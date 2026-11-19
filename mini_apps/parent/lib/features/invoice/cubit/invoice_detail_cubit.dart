import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/invoice_models.dart';
import '../data/invoice_repository.dart';
import '../data/qr_image_saver.dart';

enum InvoiceDetailStatus { loading, ready, notFound, failure }

enum QrSaveStatus { idle, saving, saved, denied, failed }

class InvoiceDetailState extends Equatable {
  const InvoiceDetailState({
    this.status = InvoiceDetailStatus.loading,
    this.invoice,
    this.qrSave = QrSaveStatus.idle,
  });

  final InvoiceDetailStatus status;
  final InvoiceDetail? invoice;

  /// Kết quả lần bấm "Lưu ảnh QR" gần nhất; trang hiện snackbar rồi gọi
  /// [InvoiceDetailCubit.ackSave].
  final QrSaveStatus qrSave;

  InvoiceDetailState copyWith({QrSaveStatus? qrSave}) => InvoiceDetailState(
    status: status,
    invoice: invoice,
    qrSave: qrSave ?? this.qrSave,
  );

  @override
  List<Object?> get props => [status, invoice, qrSave];
}

/// P03: chi tiết hóa đơn, VietQR, lưu ảnh QR (US-7.3 AC1, AC3).
class InvoiceDetailCubit extends Cubit<InvoiceDetailState> {
  InvoiceDetailCubit(this._repo, this._saver, this.invoiceId)
    : super(const InvoiceDetailState());

  final InvoiceRepository _repo;
  final QrImageSaver _saver;
  final String invoiceId;

  Future<void> load() async {
    emit(const InvoiceDetailState());
    try {
      final invoice = await _repo.detail(invoiceId);
      if (isClosed) return;
      emit(
        InvoiceDetailState(status: InvoiceDetailStatus.ready, invoice: invoice),
      );
    } catch (e) {
      if (isClosed) return;
      final notFound = e is ApiException && e.status == 404;
      emit(
        InvoiceDetailState(
          status: notFound
              ? InvoiceDetailStatus.notFound
              : InvoiceDetailStatus.failure,
        ),
      );
    }
  }

  Future<void> saveQr() async {
    final inv = state.invoice;
    final payload = inv?.qrPayload;
    if (inv == null || payload == null || state.qrSave == QrSaveStatus.saving) {
      return;
    }
    emit(state.copyWith(qrSave: QrSaveStatus.saving));
    try {
      await _saver.save(payload, name: 'teachhub-${inv.summary.code}');
      if (!isClosed) emit(state.copyWith(qrSave: QrSaveStatus.saved));
    } on QrSaveDenied {
      if (!isClosed) emit(state.copyWith(qrSave: QrSaveStatus.denied));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(qrSave: QrSaveStatus.failed));
    }
  }

  void ackSave() => emit(state.copyWith(qrSave: QrSaveStatus.idle));
}
