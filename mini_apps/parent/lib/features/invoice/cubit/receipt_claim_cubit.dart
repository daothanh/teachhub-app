import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/receipt_models.dart';
import '../data/receipt_picker.dart';
import '../data/receipt_repository.dart';

/// Bước đang chạy của lần báo chuyển khoản.
enum ClaimStage { upload, verify, claim }

/// Lỗi hiện cho người dùng; ảnh đã chọn luôn được giữ để bấm thử lại.
enum ClaimError {
  /// Ảnh sai loại/quá lớn (máy hoặc server): chọn ảnh khác.
  typeNotAllowed,
  tooLarge,
  amountInvalid,
  noteTooLong,
  offline,

  /// URL tải hết hạn hoặc kho từ chối: lần thử lại xin URL mới.
  expired,

  /// Hóa đơn đã có lần báo chờ xác nhận (409 `CONFLICT_STALE`).
  alreadyPending,

  /// Hóa đơn không còn báo được (hủy, đã đủ, hết nợ).
  notPayable,
  notFound,
  rateLimited,
  failed,
}

class ReceiptClaimState extends Equatable {
  const ReceiptClaimState({
    this.image,
    this.stage,
    this.progress = 0,
    this.error,
    this.done = false,
  });

  final ReceiptImage? image;

  /// `null` = không có bước nào đang chạy.
  final ClaimStage? stage;

  /// 0..1 của bước tải ảnh.
  final double progress;
  final ClaimError? error;
  final bool done;

  bool get busy => stage != null;

  /// Hóa đơn đã đổi ở nơi khác: trang chi tiết cần tải lại.
  bool get invoiceChanged =>
      done ||
      error == ClaimError.alreadyPending ||
      error == ClaimError.notPayable;

  ReceiptClaimState copyWith({
    ReceiptImage? image,
    ClaimStage? stage,
    double progress = 0,
    ClaimError? error,
    bool done = false,
  }) => ReceiptClaimState(
    image: image ?? this.image,
    stage: stage,
    progress: progress,
    error: error,
    done: done,
  );

  @override
  List<Object?> get props => [image, stage, progress, error, done];
}

/// Phụ huynh báo đã chuyển khoản kèm ảnh biên lai (US-7.7 AC1). Chuỗi bốn lệnh:
/// xin URL, PUT ảnh, xác nhận tệp, tạo lần báo. Mỗi bước thành công được nhớ
/// (URL, đã tải, đã xác nhận) và mỗi lệnh ghi giữ một `Idempotency-Key` qua
/// thử lại, nên lỗi mạng giữa chừng rồi bấm lại không tải hay báo trùng.
class ReceiptClaimCubit extends Cubit<ReceiptClaimState> {
  ReceiptClaimCubit(
    this._repo,
    this._picker,
    this.invoiceId, {
    DraftKeys? keys,
    DateTime Function()? now,
  }) : _keys = keys ?? DraftKeys(),
       _now = now ?? DateTime.now,
       super(const ReceiptClaimState());

  final ReceiptRepository _repo;
  final ReceiptPicker _picker;
  final String invoiceId;
  final DraftKeys _keys;
  final DateTime Function() _now;

  UploadTicket? _ticket;
  bool _uploaded = false;
  bool _verified = false;

  /// URL còn dưới ngần này thì xin URL mới (URL PUT sống rất ngắn).
  static const _ticketMargin = Duration(seconds: 15);

  void _forgetTicket() {
    _ticket = null;
    _uploaded = false;
    _verified = false;
  }

  Future<void> pickImage() async {
    if (state.busy) return;
    final ReceiptImage? img;
    try {
      img = await _picker.pick();
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: ClaimError.failed));
      return;
    }
    if (isClosed || img == null) return;
    _forgetTicket();
    final issue = checkReceipt(img.mimeType, img.size);
    emit(
      ReceiptClaimState(
        image: img,
        error: switch (issue) {
          ReceiptIssue.tooLarge => ClaimError.tooLarge,
          ReceiptIssue.typeNotAllowed => ClaimError.typeNotAllowed,
          null => null,
        },
      ),
    );
  }

  /// Số tiền (VND) 1..trần và ghi chú ≤ 300 ký tự; sai thì không gửi gì.
  static ClaimError? validate(int? amount, String note) {
    if (amount == null || amount < 1 || amount > claimAmountMax) {
      return ClaimError.amountInvalid;
    }
    if (note.trim().length > claimNoteMax) return ClaimError.noteTooLong;
    return null;
  }

  Future<void> submit({required int? amount, String note = ''}) async {
    final image = state.image;
    if (state.busy || image == null || state.done) return;
    final issue = checkReceipt(image.mimeType, image.size);
    final bad = switch (issue) {
      ReceiptIssue.tooLarge => ClaimError.tooLarge,
      ReceiptIssue.typeNotAllowed => ClaimError.typeNotAllowed,
      null => validate(amount, note),
    };
    if (bad != null) {
      emit(state.copyWith(error: bad));
      return;
    }
    var stage = ClaimStage.upload;
    try {
      final ticket = await _ensureTicket(image);
      if (!_uploaded) {
        emit(state.copyWith(stage: ClaimStage.upload));
        await _repo.put(
          ticket,
          image,
          onProgress: (p) {
            if (!isClosed) {
              emit(state.copyWith(stage: ClaimStage.upload, progress: p));
            }
          },
        );
        _uploaded = true;
      }
      if (!_verified) {
        stage = ClaimStage.verify;
        emit(state.copyWith(stage: stage));
        await _repo.complete(ticket.fileId);
        _verified = true;
      }
      stage = ClaimStage.claim;
      emit(state.copyWith(stage: stage));
      await _repo.createClaim(
        invoiceId,
        receiptFileId: ticket.fileId,
        amount: amount!,
        note: note,
        idempotencyKey: _keys.of('claim', '${ticket.fileId}|$amount|$note'),
      );
      _keys.done('claim');
      if (!isClosed) emit(state.copyWith(done: true));
    } on ApiException catch (e) {
      if (!e.retryable && stage == ClaimStage.claim) _keys.done('claim');
      if (isClosed) return;
      emit(state.copyWith(error: _classify(e, stage)));
    }
  }

  Future<UploadTicket> _ensureTicket(ReceiptImage image) async {
    final cur = _ticket;
    if (cur != null && cur.expiresAt.isAfter(_now().add(_ticketMargin))) {
      return cur;
    }
    _forgetTicket();
    emit(state.copyWith(stage: ClaimStage.upload));
    try {
      final t = await _repo.requestUpload(
        invoiceId,
        image,
        idempotencyKey: _keys.of(
          'upload',
          '${image.fileName}|${image.size}|${image.mimeType}',
        ),
      );
      _keys.done('upload');
      return _ticket = t;
    } on ApiException catch (e) {
      if (!e.retryable) _keys.done('upload');
      rethrow;
    }
  }

  ClaimError _classify(ApiException e, ClaimStage stage) {
    switch (e.code) {
      case ApiErrorCode.fileTooLarge:
        _forgetTicket();
        return ClaimError.tooLarge;
      case ApiErrorCode.fileTypeNotAllowed:
        _forgetTicket();
        return ClaimError.typeNotAllowed;
      case ApiErrorCode.invoiceNotPayable:
        return ClaimError.notPayable;
      case ApiErrorCode.conflictStale:
        if (stage == ClaimStage.verify) {
          // Kho chưa có đối tượng: tải lại cùng URL (nếu còn hạn).
          _uploaded = false;
          return ClaimError.failed;
        }
        return ClaimError.alreadyPending;
      default:
    }
    if (e.kind == ApiErrorKind.network) return ClaimError.offline;
    if (stage == ClaimStage.upload && _ticket != null && !_uploaded) {
      // Kho (không phải API) từ chối PUT: chữ ký hết hạn hoặc lệch; xin URL mới.
      if (e.kind == ApiErrorKind.forbidden ||
          e.kind == ApiErrorKind.badRequest) {
        _forgetTicket();
        return ClaimError.expired;
      }
    }
    if (e.kind == ApiErrorKind.validation) {
      if (e.fieldErrors.containsKey('amount')) return ClaimError.amountInvalid;
      if (e.fieldErrors.containsKey('note')) return ClaimError.noteTooLong;
      // Biên lai sai/đã dùng/chưa sẵn sàng: cần tệp mới.
      _forgetTicket();
      return ClaimError.failed;
    }
    return switch (e.kind) {
      ApiErrorKind.notFound => ClaimError.notFound,
      ApiErrorKind.rateLimited => ClaimError.rateLimited,
      _ => ClaimError.failed,
    };
  }
}
