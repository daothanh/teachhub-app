import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../billing/cubit/billing_periods_cubit.dart' show BillingLoad;
import '../data/receivable_models.dart';
import '../data/receivables_repository.dart';

/// Lỗi nhập mốc nhắc kiểm ở máy (server vẫn kiểm lại và trả 422).
enum OffsetError { range, duplicate, tooMany, tooFew }

class DunningPreviewState extends Equatable {
  const DunningPreviewState({
    required this.offsetDays,
    this.preview,
    this.failed = false,
  });

  final int offsetDays;

  /// `null` và không [failed]: đang tải.
  final DunningPreview? preview;
  final bool failed;

  @override
  List<Object?> get props => [offsetDays, preview, failed];
}

class DunningSettingsState extends Equatable {
  const DunningSettingsState({
    this.load = BillingLoad.loading,
    this.saved,
    this.enabled = true,
    this.offsets = const [],
    this.saving = false,
    this.justSaved = false,
    this.offsetError,
    this.serverErrors = const [],
    this.error,
    this.preview,
  });

  final BillingLoad load;

  /// Bản đã lưu trên server: so để biết có thay đổi chưa lưu.
  final DunningSettings? saved;
  final bool enabled;

  /// Mốc đang sửa, luôn tăng dần và không trùng.
  final List<int> offsets;
  final bool saving;
  final bool justSaved;
  final OffsetError? offsetError;

  /// 422 tại trường `offsetsDays`.
  final List<String> serverErrors;

  /// Lỗi tải ([load] là failure) hoặc lỗi chung của lệnh lưu.
  final ApiException? error;
  final DunningPreviewState? preview;

  bool get dirty =>
      saved != null &&
      (saved!.enabled != enabled || !listEquals(saved!.offsetsDays, offsets));

  DunningSettingsState copyWith({
    BillingLoad? load,
    DunningSettings? saved,
    bool? enabled,
    List<int>? offsets,
    bool? saving,
    bool justSaved = false,
    OffsetError? offsetError,
    List<String> serverErrors = const [],
    ApiException? error,
    Object? preview = _keep,
  }) => DunningSettingsState(
    load: load ?? this.load,
    saved: saved ?? this.saved,
    enabled: enabled ?? this.enabled,
    offsets: offsets ?? this.offsets,
    saving: saving ?? false,
    justSaved: justSaved,
    offsetError: offsetError,
    serverErrors: serverErrors,
    error: error,
    preview: identical(preview, _keep)
        ? this.preview
        : preview as DunningPreviewState?,
  );

  static const _keep = Object();

  @override
  List<Object?> get props => [
    load, saved, enabled, offsets, saving, justSaved, offsetError, //
    serverErrors, error, preview,
  ];
}

/// Cài đặt nhắc nợ của tenant (US-7.5 AC3–AC4): công tắc, mốc nhắc, lưu một lần
/// bằng `PUT`, xem trước mẫu tin của từng mốc. Không tự thử lại khi lưu lỗi.
class DunningSettingsCubit extends Cubit<DunningSettingsState> {
  DunningSettingsCubit(this._repo) : super(const DunningSettingsState());
  final ReceivablesRepository _repo;
  int _previewSeq = 0;

  Future<void> load() async {
    if (isClosed) return;
    emit(const DunningSettingsState());
    try {
      final s = await _repo.getSettings();
      if (isClosed) return;
      emit(
        DunningSettingsState(
          load: BillingLoad.ready,
          saved: s,
          enabled: s.enabled,
          offsets: s.offsetsDays,
        ),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed) return;
      emit(DunningSettingsState(load: BillingLoad.failure, error: e));
    }
  }

  void setEnabled(bool v) {
    if (state.saving) return;
    emit(state.copyWith(enabled: v));
  }

  /// Thêm mốc, giữ thứ tự tăng dần.
  void addOffset(int days) {
    if (state.saving) return;
    final cur = state.offsets;
    final err = days < dunningOffsetMin || days > dunningOffsetMax
        ? OffsetError.range
        : cur.contains(days)
        ? OffsetError.duplicate
        : cur.length >= dunningOffsetsMaxCount
        ? OffsetError.tooMany
        : null;
    if (err != null) return emit(state.copyWith(offsetError: err));
    emit(state.copyWith(offsets: [...cur, days]..sort()));
  }

  void removeOffset(int days) {
    if (state.saving) return;
    if (state.offsets.length <= 1) {
      return emit(state.copyWith(offsetError: OffsetError.tooFew));
    }
    // Xem trước đang tải của mốc vừa xóa không được hiện lại khi về tới.
    if (state.preview?.offsetDays == days) _previewSeq++;
    emit(
      state.copyWith(
        offsets: [...state.offsets]..remove(days),
        preview: state.preview?.offsetDays == days
            ? null
            : DunningSettingsState._keep,
      ),
    );
  }

  /// Đưa mốc về mặc định `-1, 0, 3, 7`.
  void resetOffsets() {
    if (state.saving) return;
    _previewSeq++;
    emit(state.copyWith(offsets: defaultDunningOffsets, preview: null));
  }

  Future<void> save() async {
    final s = state;
    if (s.saving || s.load != BillingLoad.ready) return;
    emit(s.copyWith(saving: true));
    try {
      final saved = await _repo.putSettings(
        DunningSettings(enabled: s.enabled, offsetsDays: s.offsets),
      );
      if (isClosed) return;
      emit(
        s.copyWith(
          saved: saved,
          enabled: saved.enabled,
          offsets: saved.offsetsDays,
          justSaved: true,
        ),
      );
    } on Object catch (raw) {
      final e = asApiException(raw);
      if (isClosed) return;
      final field = e.fieldErrors['offsetsDays'] ?? const <String>[];
      emit(
        s.copyWith(
          // Trường lạ hoặc không có trường thì báo chung.
          serverErrors: field,
          error: field.isEmpty || e.fieldErrors.length > 1 ? e : null,
        ),
      );
    }
  }

  /// Xem trước mẫu tin của một mốc (dữ liệu mẫu, không cần đã lưu).
  Future<void> showPreview(int offsetDays) async {
    final seq = ++_previewSeq;
    emit(state.copyWith(preview: DunningPreviewState(offsetDays: offsetDays)));
    try {
      final p = await _repo.preview(offsetDays);
      if (isClosed || seq != _previewSeq) return;
      emit(
        state.copyWith(
          preview: DunningPreviewState(offsetDays: offsetDays, preview: p),
        ),
      );
    } on Object {
      if (isClosed || seq != _previewSeq) return;
      emit(
        state.copyWith(
          preview: DunningPreviewState(offsetDays: offsetDays, failed: true),
        ),
      );
    }
  }
}
