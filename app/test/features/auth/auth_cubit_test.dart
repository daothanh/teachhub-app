import 'package:app/features/auth/auth_config.dart';
import 'package:app/features/auth/auth_cubit.dart';
import 'package:app/features/auth/teachhub_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_utils/tasco_utils.dart';

const _user = TeachHubUser(
  id: 'u1',
  email: 'co.lan@example.com',
  permissions: ['role:parent'],
);

/// Repository giả: kết quả đặt trước, ghi lại các lệnh đã gọi.
class _Repo implements AuthRepository<TeachHubUser> {
  final calls = <String>[];
  Object? loginResult = const AuthSuccess(_user);
  Object? meResult = _user;
  Object? logoutError;
  bool hasToken = false;
  TeachHubUser? cached;

  @override
  Future<AuthResult<TeachHubUser>> login(Map<String, dynamic> c) async {
    calls.add('login:${c['code']}');
    final r = loginResult;
    if (r is Exception) throw r;
    return r! as AuthResult<TeachHubUser>;
  }

  @override
  Future<TeachHubUser> getUserInfo() async {
    calls.add('me');
    final r = meResult;
    if (r is Exception) throw r;
    return r! as TeachHubUser;
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    if (logoutError case final Object e) throw e;
  }

  @override
  Future<void> clearSession() async => calls.add('clearSession');

  @override
  Future<bool> hasValidToken() async => hasToken;

  @override
  Future<TeachHubUser?> cachedUser() async => cached;

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _Repo repo;
  late AuthEventBus bus;
  late AppAuthCubit cubit;
  late List<AuthEvent> events;

  setUp(() {
    repo = _Repo();
    bus = AuthEventBus();
    events = [];
    bus.stream.listen(events.add);
    cubit = AppAuthCubit(repository: repo, authEventBus: bus);
  });

  tearDown(() async {
    await cubit.close();
    bus.dispose();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('login', () {
    test('thành công: có user, phát authenticated', () async {
      await cubit.login(
        emailOtpCredentials(email: 'co.lan@example.com', code: '482918'),
      );
      await flush();
      expect(cubit.state.statusLogin, LoadingStatus.success);
      expect(cubit.state.user, _user);
      expect(cubit.isAuthenticated, isTrue);
      expect(repo.calls, ['login:482918', 'me']);
      expect(events, [AuthEvent.authenticated]);
    });

    test(
      'lỗi API: failure kèm lỗi, chưa có user, không phát sự kiện',
      () async {
        final error = Exception('OTP_INVALID');
        repo.loginResult = error;
        await cubit.login(
          emailOtpCredentials(email: 'co.lan@example.com', code: '000000'),
        );
        await flush();
        expect(cubit.state.statusLogin, LoadingStatus.failure);
        expect(cubit.state.error, error);
        expect(cubit.isAuthenticated, isFalse);
        expect(events, isEmpty);
      },
    );

    test('đăng nhập lại sau lỗi xóa lỗi cũ', () async {
      repo.loginResult = Exception('OTP_INVALID');
      await cubit.login(
        emailOtpCredentials(email: 'co.lan@example.com', code: '000000'),
      );
      repo.loginResult = const AuthSuccess(_user);
      await cubit.login(
        emailOtpCredentials(email: 'co.lan@example.com', code: '482918'),
      );
      expect(cubit.state.statusLogin, LoadingStatus.success);
      expect(cubit.state.error, isNull);
    });
  });

  group('initSession', () {
    test('không có token: statusCheckToken failure, chưa đăng nhập', () async {
      await cubit.initSession();
      expect(cubit.state.statusCheckToken, LoadingStatus.failure);
      expect(cubit.state.user, isNull);
      expect(events, isEmpty);
    });

    test('có token và user lưu: vào ngay, làm mới user ngầm', () async {
      repo
        ..hasToken = true
        ..cached = _user
        ..meResult = const TeachHubUser(id: 'u1', email: 'moi@example.com');
      await cubit.initSession();
      await flush();
      expect(cubit.state.statusCheckToken, LoadingStatus.success);
      expect(cubit.state.user?.email, 'moi@example.com');
      expect(events, [AuthEvent.authenticated]);
    });

    test('có token, không có user lưu, /auth/me lỗi: failure', () async {
      repo
        ..hasToken = true
        ..meResult = Exception('offline');
      await cubit.initSession();
      expect(cubit.state.statusCheckToken, LoadingStatus.failure);
      expect(cubit.state.user, isNull);
    });
  });

  group('đăng xuất', () {
    setUp(() async {
      await cubit.login(
        emailOtpCredentials(email: 'co.lan@example.com', code: '482918'),
      );
      await flush();
      events.clear();
    });

    test('logout: phát loggedOut, gọi server, xóa user', () async {
      await cubit.logout();
      await flush();
      expect(cubit.state.statusLogout, LoadingStatus.success);
      expect(cubit.state.user, isNull);
      expect(repo.calls.last, 'logout');
      expect(events, [AuthEvent.loggedOut]);
    });

    test('server lỗi: vẫn xóa user ở máy, báo failure', () async {
      repo.logoutError = Exception('offline');
      await cubit.logout();
      expect(cubit.state.statusLogout, LoadingStatus.failure);
      expect(cubit.state.user, isNull);
    });

    test(
      'sessionExpired (refresh hỏng): xóa phiên, không gọi server',
      () async {
        bus.emit(AuthEvent.sessionExpired);
        await flush();
        await flush();
        expect(cubit.state.user, isNull);
        expect(cubit.state.statusRefreshToken, LoadingStatus.failure);
        expect(repo.calls, isNot(contains('logout')));
        expect(repo.calls.last, 'clearSession');
        expect(events, contains(AuthEvent.loggedOut));
      },
    );
  });

  test('đóng cubit rồi nhận sessionExpired muộn: không ném lỗi', () async {
    await cubit.close();
    bus.emit(AuthEvent.sessionExpired);
    await flush();
  });
}
