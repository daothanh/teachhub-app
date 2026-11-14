import 'package:app/data/model/user_model.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_utils/tasco_utils.dart';

// ── Inline fake repository ────────────────────────────────────────────────────

class _FakeRepo implements AuthRepository<UserModel> {
  @override
  Future<AuthResult<UserModel>> login(Map<String, dynamic> credentials) async =>
      const AuthSuccess(UserModel(id: '0', name: 'Fake'));

  @override
  Future<UserModel> loginWithSso({
    required String providerId,
    required SsoResult ssoResult,
  }) async => const UserModel(id: '0', name: 'Fake SSO');

  @override
  Future<UserModel> getUserInfo() async =>
      const UserModel(id: '0', name: 'Fake');

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<UserModel?> cachedUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}
}

// ── MockAppAuthCubit ─────────────────────────────────────────────────────────

/// [AppAuthCubit] subclass pre-seeded with any desired state via [emit].
/// Overrides [initSession] as a no-op so widget tests skip all async IO.
class MockAppAuthCubit extends AppAuthCubit {
  MockAppAuthCubit(AppAuthState preloadedState)
    : super(repository: _FakeRepo(), authEventBus: AuthEventBus()) {
    emit(preloadedState);
  }

  @override
  Future<void> initSession() async {}
}

// ── Builder helpers ───────────────────────────────────────────────────────────

/// Create a [MockAppAuthCubit] with an authenticated [UserModel].
MockAppAuthCubit buildAuthCubit({
  String name = 'Test User',
  String username = 'testuser',
  LoadingStatus statusCheckToken = LoadingStatus.success,
}) => MockAppAuthCubit(
  AppAuthState(
    user: UserModel(id: '1', name: name, username: username),
    statusCheckToken: statusCheckToken,
  ),
);

/// Create a [MockAppAuthCubit] in the initial unauthenticated state.
MockAppAuthCubit buildUnauthCubit() => MockAppAuthCubit(AppAuthState.initial());
