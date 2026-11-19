import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../../classes/data/class_models.dart';
import '../../classes/data/classes_repository.dart';
import '../data/invite_models.dart';
import '../data/invite_repository.dart';

/// Một phụ huynh trong danh sách "Mời tất cả" của lớp.
class BulkInviteItem extends Equatable {
  const BulkInviteItem({
    required this.studentId,
    required this.studentName,
    required this.guardian,
    this.link,
    this.error,
    this.shared = false,
  });

  final String studentId;
  final String studentName;
  final RosterGuardian guardian;

  /// Có sau khi tạo hoặc gửi lại thành công.
  final InviteLink? link;
  final ApiException? error;

  /// Giáo viên đã mở bảng chia sẻ cho người này (dấu "đã gửi").
  final bool shared;

  BulkInviteItem copyWith({
    InviteLink? link,
    ApiException? error,
    bool clearError = false,
    bool? shared,
  }) => BulkInviteItem(
    studentId: studentId,
    studentName: studentName,
    guardian: guardian,
    link: link ?? this.link,
    error: clearError ? null : error ?? this.error,
    shared: shared ?? this.shared,
  );

  @override
  List<Object?> get props => [
    studentId,
    studentName,
    guardian,
    link,
    error,
    shared,
  ];
}

enum BulkInviteStatus { loading, working, done, failure }

class BulkInviteState extends Equatable {
  const BulkInviteState({
    this.status = BulkInviteStatus.loading,
    this.items = const [],
    this.error,
  });

  final BulkInviteStatus status;
  final List<BulkInviteItem> items;

  /// Lỗi tải danh sách lớp ([BulkInviteStatus.failure]).
  final ApiException? error;

  /// Số người đã có link.
  int get ready => items.where((i) => i.link != null).length;

  @override
  List<Object?> get props => [status, items, error];
}

/// "Mời tất cả phụ huynh chưa kích hoạt" của lớp (US-1.6 AC3). Chỉ lặp trên
/// phụ huynh `notInvited` (tạo lời mời) và `expired` (gửi lại bằng
/// `latestInvite.id`); bỏ qua `invited` (đang còn hạn) và `activated`.
/// Tạo lần lượt từng người để không dồn tải; người lỗi thử lại riêng được.
class BulkInviteCubit extends Cubit<BulkInviteState> {
  BulkInviteCubit(this._classes, this._invites, this.classId, {Random? random})
    : _random = random,
      super(const BulkInviteState());

  final ClassesRepository _classes;
  final InviteRepository _invites;
  final String classId;
  final Random? _random;
  final _keys = <String, String>{};

  /// Phụ huynh của [roster] cần mời, theo thứ tự danh sách.
  static List<BulkInviteItem> targets(List<RosterEntry> roster) => [
    for (final e in roster)
      for (final g in e.guardians)
        if (g.inviteStatus == GuardianInviteStatus.notInvited ||
            (g.inviteStatus == GuardianInviteStatus.expired &&
                g.latestInvite != null))
          BulkInviteItem(
            studentId: e.studentId,
            studentName: e.fullName,
            guardian: g,
          ),
  ];

  Future<void> start() async {
    emit(const BulkInviteState());
    try {
      final roster = await _classes.roster(classId);
      if (isClosed) return;
      emit(
        BulkInviteState(
          status: BulkInviteStatus.working,
          items: targets(roster),
        ),
      );
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(BulkInviteState(status: BulkInviteStatus.failure, error: e));
      return;
    }
    for (var i = 0; i < state.items.length && !isClosed; i++) {
      await _issue(i);
    }
    if (!isClosed) {
      emit(BulkInviteState(status: BulkInviteStatus.done, items: state.items));
    }
  }

  /// Thử lại người bị lỗi.
  Future<void> retry(int index) => _issue(index);

  void markShared(int index) => _set(index, (i) => i.copyWith(shared: true));

  Future<void> _issue(int index) async {
    final item = state.items[index];
    if (item.link != null) return;
    _set(index, (i) => i.copyWith(clearError: true));
    final key = _keys[item.guardian.id] ??= uuidV4(_random ?? Random.secure());
    try {
      final g = item.guardian;
      final link = g.inviteStatus == GuardianInviteStatus.expired
          ? await _invites.resend(g.latestInvite!.id, idempotencyKey: key)
          : await _invites.create(item.studentId, g.id, idempotencyKey: key);
      _keys.remove(g.id);
      _set(index, (i) => i.copyWith(link: link));
    } on ApiException catch (e) {
      if (!e.retryable) _keys.remove(item.guardian.id);
      _set(index, (i) => i.copyWith(error: e));
    }
  }

  void _set(int index, BulkInviteItem Function(BulkInviteItem) f) {
    if (isClosed) return;
    final items = [...state.items];
    items[index] = f(items[index]);
    emit(
      BulkInviteState(status: state.status, items: items, error: state.error),
    );
  }
}
