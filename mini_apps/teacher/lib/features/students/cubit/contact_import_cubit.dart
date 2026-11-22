import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/contacts_service.dart';
import '../data/student_models.dart';
import '../data/student_repository.dart';

enum ImportPhase {
  /// Chưa hỏi quyền, hoặc đang hỏi.
  requesting,
  denied,
  permanentlyDenied,
  picking,
  review,
}

enum RowStatus { pending, saving, saved, duplicate, failed }

/// Một học viên nháp. Không có `toString`: tránh lọt tên/SĐT vào log.
class DraftRow extends Equatable {
  const DraftRow({
    required this.id,
    required this.name,
    this.phone = '',
    String? guardianName,
    this.status = RowStatus.pending,
    this.candidates = const [],
    this.error,
    this.savedId,
  }) : guardianName = guardianName ?? name;

  final String id;
  final String name;
  final String phone;

  /// Tên phụ huynh 1, điền sẵn bằng tên liên hệ; chỉ dùng khi có [phone].
  final String guardianName;
  final RowStatus status;
  final List<StudentCandidate> candidates;
  final ApiException? error;
  final String? savedId;

  static final phoneRe = RegExp(r'^\+?[0-9]{8,15}$');

  bool get nameValid => name.trim().isNotEmpty;
  bool get phoneValid => phone.trim().isEmpty || phoneRe.hasMatch(phone.trim());
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get guardianValid => !hasPhone || guardianName.trim().isNotEmpty;
  bool get editable =>
      status == RowStatus.pending ||
      status == RowStatus.failed ||
      status == RowStatus.duplicate;

  /// Chưa lưu được và dữ liệu hợp lệ → được gửi (lại) khi bấm Lưu.
  bool get sendable => nameValid && phoneValid && guardianValid && editable;

  /// Tên liên hệ là họ tên học viên; SĐT là SĐT phụ huynh 1 (API bắt buộc
  /// `guardians[].fullName`, nên có SĐT thì phải có tên phụ huynh).
  StudentDraft toDraft() {
    final p = phone.trim();
    return StudentDraft(
      fullName: name.trim(),
      guardians: p.isEmpty
          ? const []
          : [GuardianDraft(fullName: guardianName.trim(), phone: p)],
    );
  }

  DraftRow copyWith({
    String? name,
    String? phone,
    String? guardianName,
    RowStatus? status,
    List<StudentCandidate>? candidates,
    ApiException? error,
    String? savedId,
  }) => DraftRow(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    guardianName: guardianName ?? this.guardianName,
    status: status ?? this.status,
    candidates: candidates ?? const [],
    error: status == RowStatus.failed ? error : null,
    savedId: savedId ?? this.savedId,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    guardianName,
    status,
    candidates,
    error,
    savedId,
  ];
}

class ContactImportState extends Equatable {
  const ContactImportState({
    this.phase = ImportPhase.requesting,
    this.contacts = const [],
    this.selected = const {},
    this.rows = const [],
    this.saving = false,
    this.loadFailed = false,
  });

  final ImportPhase phase;
  final List<PickableContact> contacts;
  final Set<String> selected;
  final List<DraftRow> rows;
  final bool saving;
  final bool loadFailed;

  bool get hasSaved => rows.any((r) => r.status == RowStatus.saved);

  /// Dòng sẽ được gửi khi bấm Lưu; dòng trùng chờ người dùng chọn ở hộp thoại.
  Iterable<DraftRow> get toSend =>
      rows.where((r) => r.sendable && r.status != RowStatus.duplicate);
  bool get canSave => !saving && toSend.isNotEmpty;

  ContactImportState copyWith({
    ImportPhase? phase,
    List<PickableContact>? contacts,
    Set<String>? selected,
    List<DraftRow>? rows,
    bool? saving,
    bool? loadFailed,
  }) => ContactImportState(
    phase: phase ?? this.phase,
    contacts: contacts ?? this.contacts,
    selected: selected ?? this.selected,
    rows: rows ?? this.rows,
    saving: saving ?? this.saving,
    loadFailed: loadFailed ?? this.loadFailed,
  );

  @override
  List<Object?> get props => [
    phase,
    contacts,
    selected,
    rows,
    saving,
    loadFailed,
  ];
}

class ContactImportCubit extends Cubit<ContactImportState> {
  ContactImportCubit(this._contacts, this._students, {Random? random})
    : _random = random ?? Random.secure(),
      super(const ContactImportState());

  final ContactsService _contacts;
  final StudentRepository _students;
  final Random _random;

  // Khóa idempotency theo dòng: giữ khi thử lại cùng nội dung, đổi khi nội dung
  // (hoặc cờ confirmNew) đổi.
  final _keys = <String, ({String key, StudentDraft draft, bool confirmNew})>{};

  // Dòng đã "Không phải em này": giữ cờ confirmNew cho các lần lưu sau.
  final _confirmed = <String>{};

  // Dòng đã sửa tay, theo id liên hệ: Quay lại rồi Tiếp tục không mất.
  final _memo = <String, DraftRow>{};

  /// Hỏi quyền rồi nạp danh bạ. Chỉ gọi sau khi người dùng bấm nút.
  Future<void> start() async {
    emit(state.copyWith(phase: ImportPhase.requesting, loadFailed: false));
    final ContactsAccess access;
    try {
      access = await _contacts.requestAccess();
    } catch (_) {
      if (isClosed) return;
      return emit(state.copyWith(phase: ImportPhase.denied));
    }
    if (isClosed) return;
    switch (access) {
      case ContactsAccess.denied:
        return emit(state.copyWith(phase: ImportPhase.denied));
      case ContactsAccess.permanentlyDenied:
        return emit(state.copyWith(phase: ImportPhase.permanentlyDenied));
      case ContactsAccess.granted:
        break;
    }
    try {
      final list = await _contacts.load();
      if (isClosed) return;
      emit(state.copyWith(phase: ImportPhase.picking, contacts: list));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: ImportPhase.picking,
          contacts: const [],
          loadFailed: true,
        ),
      );
    }
  }

  Future<void> openSettings() => _contacts.openSettings();

  void toggle(String contactId) {
    final next = {...state.selected};
    if (!next.remove(contactId)) next.add(contactId);
    emit(state.copyWith(selected: next));
  }

  /// Chọn xong → danh sách nháp theo thứ tự danh bạ. Bỏ danh sách liên hệ
  /// khỏi state (có thể rất lớn); Quay lại thì nạp lại.
  void confirmSelection() {
    final rows = [
      for (final c in state.contacts)
        if (state.selected.contains(c.id))
          _memo[c.id] ??
              DraftRow(
                id: c.id,
                name: c.name,
                phone: normalizePhone(c.phone) ?? '',
              ),
    ];
    emit(
      state.copyWith(phase: ImportPhase.review, rows: rows, contacts: const []),
    );
  }

  Future<void> backToPicking() {
    _memo.addAll({for (final r in state.rows) r.id: r});
    return start();
  }

  void edit(String id, {String? name, String? phone, String? guardianName}) =>
      _update(
        id,
        (r) => r.editable
            ? r.copyWith(
                name: name,
                phone: phone,
                guardianName: guardianName,
                status: RowStatus.pending,
              )
            : r,
      );

  void remove(String id) {
    if (state.saving) return;
    _keys.remove(id);
    _confirmed.remove(id);
    _memo.remove(id);
    emit(
      state.copyWith(
        rows: [
          for (final r in state.rows)
            if (r.id != id) r,
        ],
        selected: {...state.selected}..remove(id),
      ),
    );
  }

  /// Lưu lần lượt từng dòng còn chưa lưu; lỗi một dòng không chặn dòng khác.
  Future<void> saveAll() async {
    if (state.saving) return;
    emit(state.copyWith(saving: true));
    try {
      for (final id in [for (final r in state.toSend) r.id]) {
        if (isClosed) return;
        await _save(id);
      }
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  /// "Không phải em này" ở hộp thoại trùng: gửi lại kèm `confirmNew`.
  Future<void> confirmNew(String id) async {
    if (state.saving) return;
    _confirmed.add(id);
    emit(state.copyWith(saving: true));
    try {
      await _save(id);
    } finally {
      if (!isClosed) emit(state.copyWith(saving: false));
    }
  }

  /// "Đúng là em này": dùng hồ sơ có sẵn.
  void pickExisting(String id, StudentCandidate c) =>
      _update(id, (r) => r.copyWith(status: RowStatus.saved, savedId: c.id));

  Future<void> _save(String id) async {
    final confirmNew = _confirmed.contains(id);
    final row = state.rows.firstWhere((r) => r.id == id);
    final draft = row.toDraft();
    final prev = _keys[id];
    final key =
        prev != null && prev.draft == draft && prev.confirmNew == confirmNew
        ? prev.key
        : uuidV4(_random);
    _keys[id] = (key: key, draft: draft, confirmNew: confirmNew);
    _update(id, (r) => r.copyWith(status: RowStatus.saving));
    try {
      final s = await _students.create(
        draft,
        idempotencyKey: key,
        confirmNew: confirmNew,
      );
      _update(id, (r) => r.copyWith(status: RowStatus.saved, savedId: s.id));
    } on StudentDuplicateException catch (e) {
      _update(
        id,
        (r) =>
            r.copyWith(status: RowStatus.duplicate, candidates: e.candidates),
      );
    } on ApiException catch (e) {
      // Lỗi chắc chắn không ghi (4xx): lần lưu sau dùng khóa mới.
      if (!e.retryable) _keys.remove(id);
      _update(id, (r) => r.copyWith(status: RowStatus.failed, error: e));
    } catch (_) {
      // Lỗi lạ: dòng này thất bại, không treo cả lượt lưu.
      _update(
        id,
        (r) => r.copyWith(
          status: RowStatus.failed,
          error: const ApiException.unexpected(),
        ),
      );
    }
  }

  void _update(String id, DraftRow Function(DraftRow) f) {
    if (isClosed) return;
    emit(
      state.copyWith(rows: [for (final r in state.rows) r.id == id ? f(r) : r]),
    );
  }
}
