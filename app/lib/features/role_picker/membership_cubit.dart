import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_utils/tasco_utils.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

class MembershipState extends Equatable {
  const MembershipState({
    this.statusLoad = LoadingStatus.initial,
    this.statusCreate = LoadingStatus.initial,
    this.memberships = const [],
    this.active,
    this.error,
  });

  final LoadingStatus statusLoad;
  final LoadingStatus statusCreate;
  final List<Membership> memberships;
  final Membership? active;
  final Object? error;

  /// Quyền `role:*` theo mọi membership — nguồn cho `PermissionGuard`.
  Set<String> get permissions => {
    for (final m in memberships) m.role.permission,
  };

  MembershipState copyWith({
    LoadingStatus? statusLoad,
    LoadingStatus? statusCreate,
    List<Membership>? memberships,
    Membership? active,
    bool clearActive = false,
    Object? error,
  }) => MembershipState(
    statusLoad: statusLoad ?? this.statusLoad,
    statusCreate: statusCreate ?? this.statusCreate,
    memberships: memberships ?? this.memberships,
    active: clearActive ? null : (active ?? this.active),
    error: error,
  );

  @override
  List<Object?> get props => [
    statusLoad,
    statusCreate,
    memberships,
    active,
    error,
  ];
}

/// Vai trò của người dùng và vai trò đang mở (spec §3.7, US-0.10, US-0.11).
///
/// Đổi vai trò không đăng nhập lại, không đổi JWT. Vai trò đang mở được lưu
/// cục bộ và báo lên API (`PUT /me/active-membership`).
class MembershipCubit extends Cubit<MembershipState> {
  MembershipCubit({
    required Dio api,
    required SharedPreferences prefs,
    required ActiveMembership activeMembership,
  }) : _api = api,
       _prefs = prefs,
       _active = activeMembership,
       super(const MembershipState());

  final Dio _api;
  final SharedPreferences _prefs;
  final ActiveMembership _active;

  static const _activeKey = 'active_membership_id';

  @override
  void emit(MembershipState state) {
    if (isClosed) return;
    _active.value = state.active;
    super.emit(state);
  }

  /// `GET /me/memberships` → `{ items: [...], lastMembershipId? }`.
  ///
  /// Vai trò mở lại: lần chọn trên máy này, rồi lần dùng gần nhất trên
  /// server, rồi vai trò duy nhất nếu chỉ có một.
  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(statusLoad: LoadingStatus.loading));
    try {
      final res = await _api.get<Map<String, dynamic>>('/me/memberships');
      final body = res.data ?? const {};
      final items = [
        for (final raw in body['items'] as List? ?? const [])
          ?Membership.fromJson(raw as Map<String, dynamic>),
      ];
      Membership? byId(String? id) =>
          id == null ? null : items.where((m) => m.id == id).firstOrNull;
      final active =
          byId(_prefs.getString(_activeKey)) ??
          byId(body['lastMembershipId'] as String?) ??
          (items.length == 1 ? items.single : null);
      emit(
        state.copyWith(
          statusLoad: LoadingStatus.success,
          memberships: items,
          active: active,
          clearActive: active == null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(statusLoad: LoadingStatus.failure, error: e));
    }
  }

  /// Mở một vai trò đã có.
  Future<void> select(Membership membership) async {
    emit(state.copyWith(active: membership));
    await _prefs.setString(_activeKey, membership.id);
    // Chỉ để mở đúng vai trò trên máy khác; lỗi không chặn người dùng.
    unawaited(
      _api
          .put<void>(
            '/me/active-membership',
            data: {'membershipId': membership.id},
          )
          .catchError((Object e) {
            log('active-membership sync failed: $e', name: 'membership');
            return Response<void>(requestOptions: RequestOptions());
          }),
    );
  }

  /// Thêm vai trò (T01c): Giáo viên tạo không gian (`POST /workspaces`), Phụ
  /// huynh/Học sinh thêm vai trò rỗng (`POST /me/roles`), rồi mở vai trò đó.
  Future<void> addRole(MembershipRole role) async {
    emit(state.copyWith(statusCreate: LoadingStatus.loading));
    try {
      if (role == MembershipRole.tenantOwner) {
        await _api.post<void>('/workspaces', data: const <String, dynamic>{});
      } else {
        await _api.post<void>('/me/roles', data: {'role': role.wire});
      }
      await load(silent: true);
      final created = state.memberships
          .where((m) => m.role == role)
          .firstOrNull;
      if (created != null) await select(created);
      emit(state.copyWith(statusCreate: LoadingStatus.success));
    } catch (e) {
      emit(state.copyWith(statusCreate: LoadingStatus.failure, error: e));
    }
  }

  /// Đăng xuất: quên vai trò của phiên này.
  Future<void> clear() async {
    await _prefs.remove(_activeKey);
    emit(const MembershipState());
  }
}
