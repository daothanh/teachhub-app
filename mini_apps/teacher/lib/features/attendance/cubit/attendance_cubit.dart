import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/attendance_models.dart';
import '../data/attendance_repository.dart';

enum AttendanceLoad { loading, ready, failure }

/// Vì sao không sửa được (nút Lưu tắt).
enum ReadOnlyReason { cancelled, windowClosed }

typedef StudentDraft = ({AttendanceStatus status, String? note});

class AttendanceState extends Equatable {
  const AttendanceState({
    this.load = AttendanceLoad.loading,
    this.sheet,
    this.drafts = const {},
    this.saving = false,
    this.saved = false,
    this.saveFailed = false,
    this.offline = false,
    this.error,
    this.readOnly,
  });

  final AttendanceLoad load;
  final SessionSheet? sheet;

  /// Thay đổi chưa lưu, theo `studentId`.
  final Map<String, StudentDraft> drafts;
  final bool saving;

  /// Đã ghi cục bộ xong: màn đóng lại.
  final bool saved;
  final bool saveFailed;

  /// Lần làm mới gần nhất không có mạng: đang hiện bản đã lưu.
  final bool offline;
  final ApiException? error;

  /// null = sửa được.
  final ReadOnlyReason? readOnly;

  bool get editable => readOnly == null;

  AttendanceStatus statusOf(SheetStudent s) =>
      drafts[s.studentId]?.status ?? s.status ?? AttendanceStatus.present;

  String? noteOf(SheetStudent s) =>
      drafts.containsKey(s.studentId) ? drafts[s.studentId]!.note : s.note;

  /// Học viên phải ghi: chưa từng điểm danh (ghi rõ "Có mặt") hoặc đã đổi.
  List<AttendanceEntry> get changes => [
    for (final s in sheet?.students ?? const <SheetStudent>[])
      if (s.status == null ||
          statusOf(s) != s.status ||
          (noteOf(s) ?? '') != (s.note ?? ''))
        (
          studentId: s.studentId,
          status: statusOf(s),
          note: (noteOf(s) ?? '').isEmpty ? null : noteOf(s),
        ),
  ];

  bool get canSave =>
      editable &&
      !saving &&
      (sheet?.students.isNotEmpty ?? false) &&
      changes.isNotEmpty;

  @override
  List<Object?> get props => [
    load,
    sheet,
    drafts,
    saving,
    saved,
    saveFailed,
    offline,
    error,
    readOnly,
  ];
}

/// T04: điểm danh 1 chạm. Mặc định mọi em "Có mặt"; chạm một em thì đổi vòng
/// qua 4 trạng thái. Lưu ghi cục bộ (không chờ mạng) rồi SyncEngine đẩy lên.
class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(
    this._repo,
    this.sessionId, {
    AttendanceAnalytics analytics = const NoopAttendanceAnalytics(),
  }) : _analytics = analytics,
       super(const AttendanceState());

  final AttendanceRepository _repo;
  final String sessionId;
  final AttendanceAnalytics _analytics;
  StreamSubscription<SessionSheet?>? _sub;

  /// Có dòng điểm danh nào đã được ghi trước lần mở này: Lưu là "sửa".
  bool get _isEdit =>
      state.sheet?.students.any((s) => s.status != null) ?? false;

  Future<void> load() async {
    unawaited(_sub?.cancel()); // không chờ: sự kiện dừng ngay khi hủy
    emit(const AttendanceState());
    _sub = _repo.watchSheet(sessionId).listen(_onSheet, onError: _onError);
    await refresh();
  }

  void _onError(Object e) {
    if (isClosed) return;
    final hasRoster = state.sheet?.students.isNotEmpty ?? false;
    emit(
      _copy(
        load: hasRoster ? AttendanceLoad.ready : AttendanceLoad.failure,
        error: e is ApiException ? e : const ApiException.unexpected(),
      ),
    );
  }

  Timer? _expiry;

  /// Hạn sửa trôi qua lúc đang mở: tính lại chỉ-xem đúng lúc hết hạn.
  void _scheduleExpiry(SessionSheet sheet) {
    _expiry?.cancel();
    final until = sheet.editableUntil;
    if (until == null || _readOnly(sheet) != null) return;
    _expiry = Timer(until.difference(_repo.serverNow()), () {
      final s = state.sheet;
      if (isClosed || s == null) return;
      emit(_copy(readOnly: _readOnly(s), setReadOnly: true));
    });
  }

  void _onSheet(SessionSheet? sheet) {
    if (isClosed || sheet == null) return;
    _scheduleExpiry(sheet);
    final ready =
        sheet.students.isNotEmpty || state.load == AttendanceLoad.ready;
    emit(
      AttendanceState(
        load: ready ? AttendanceLoad.ready : state.load,
        sheet: sheet,
        drafts: state.drafts,
        saving: state.saving,
        saved: state.saved,
        saveFailed: state.saveFailed,
        offline: state.offline,
        error: state.error,
        readOnly: _readOnly(sheet),
      ),
    );
  }

  /// Hạn sửa theo `editableUntil` của hợp đồng so với giờ server ước lượng
  /// (không tin giờ máy); chưa có hạn (cache cũ) thì theo `canEdit` lần tải gần nhất.
  ReadOnlyReason? _readOnly(SessionSheet s) {
    if (s.cancelled) return ReadOnlyReason.cancelled;
    final now = _repo.serverNow();
    final until = s.editableUntil;
    final closed = until != null ? !now.isBefore(until) : s.canEdit == false;
    return closed ? ReadOnlyReason.windowClosed : null;
  }

  Future<void> refresh() async {
    try {
      await _repo.refreshSheet(sessionId);
      if (isClosed) return;
      emit(_copy(load: AttendanceLoad.ready, offline: false, clearError: true));
    } catch (e) {
      // Mọi lỗi (kể cả CSDL) thành trạng thái lỗi có nút Thử lại.
      if (isClosed) return;
      final hasRoster = state.sheet?.students.isNotEmpty ?? false;
      emit(
        _copy(
          load: hasRoster ? AttendanceLoad.ready : AttendanceLoad.failure,
          offline: e is ApiException && e.kind == ApiErrorKind.network,
          error: e is ApiException ? e : const ApiException.unexpected(),
        ),
      );
    }
  }

  /// Chạm một em: đổi vòng Có mặt → Muộn → Vắng có phép → Vắng không phép.
  void tap(String studentId) {
    final sheet = state.sheet;
    if (!state.editable || state.saving || sheet == null) return;
    final s = sheet.students.where((s) => s.studentId == studentId).firstOrNull;
    if (s == null) return;
    _draft(s, status: state.statusOf(s).next, note: state.noteOf(s));
  }

  void setNote(String studentId, String text) {
    final sheet = state.sheet;
    if (!state.editable || state.saving || sheet == null) return;
    final s = sheet.students.where((s) => s.studentId == studentId).firstOrNull;
    if (s == null) return;
    final note = text.characters.take(attendanceNoteMax).toString();
    _draft(s, status: state.statusOf(s), note: note);
  }

  void _draft(
    SheetStudent s, {
    required AttendanceStatus status,
    String? note,
  }) => emit(
    _copy(drafts: {...state.drafts, s.studentId: (status: status, note: note)}),
  );

  /// Ghi cục bộ (một giao dịch, không chờ mạng) rồi đóng màn.
  Future<void> save() async {
    if (!state.canSave) return;
    final entries = state.changes;
    final edit = _isEdit;
    emit(_copy(saving: true, saveFailed: false));
    try {
      await _repo.save(sessionId, entries);
    } catch (_) {
      if (isClosed) return;
      emit(_copy(saving: false, saveFailed: true));
      return;
    }
    if (isClosed) return;
    _analytics.attendanceSaved(
      students: state.sheet?.students.length ?? entries.length,
      absent: [
        for (final s in state.sheet?.students ?? const <SheetStudent>[])
          if (state.statusOf(s).absent) s,
      ].length,
      edit: edit,
    );
    emit(_copy(saving: false, saved: true, drafts: const {}));
  }

  /// Bỏ các bản ghi bị server từ chối của buổi này.
  Future<void> discardFailed() async {
    try {
      await _repo.discardFailed(sessionId);
    } catch (_) {
      if (!isClosed) emit(_copy(error: const ApiException.unexpected()));
      return;
    }
    if (isClosed) return;
    emit(_copy(drafts: const {}));
  }

  AttendanceState _copy({
    AttendanceLoad? load,
    Map<String, StudentDraft>? drafts,
    bool? saving,
    bool? saved,
    bool? saveFailed,
    bool? offline,
    ApiException? error,
    bool clearError = false,
    ReadOnlyReason? readOnly,
    bool setReadOnly = false,
  }) => AttendanceState(
    load: load ?? state.load,
    sheet: state.sheet,
    drafts: drafts ?? state.drafts,
    saving: saving ?? state.saving,
    saved: saved ?? state.saved,
    saveFailed: saveFailed ?? state.saveFailed,
    offline: offline ?? state.offline,
    error: clearError ? null : error ?? state.error,
    readOnly: setReadOnly ? readOnly : state.readOnly,
  );

  @override
  Future<void> close() async {
    _expiry?.cancel();
    await _sub?.cancel();
    return super.close();
  }
}
