import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_notifications/tasco_notifications.dart';
import 'package:tasco_storage/tasco_storage.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/model/user_model.dart';
import '../features/auth/auth_cubit.dart';
import 'const_key.dart';

final _authConfig = AuthConfig<UserModel>(
  loginPath: 'login',
  refreshPath: 'refresh',
  mePath: 'me',
  logoutPath: 'logout',
  ssoPath: 'sso',
  ssoPathBuilder: (providerId) => 'sso/$providerId',
  parseLoginUser: (body) {
    final userMap = body['user'] is Map<String, dynamic>
        ? body['user'] as Map<String, dynamic>
        : (body['data'] is Map<String, dynamic>
              ? body['data'] as Map<String, dynamic>
              : body);
    return UserModel.fromLoginJson(userMap);
  },
  parseProfileUser: (body) {
    final profileMap = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    return UserModel.fromProfileJson(profileMap);
  },
);

Future<void> repositoryModule(GetIt getIt) async {
  getIt
    ..registerLazySingleton<AuthRepository<UserModel>>(
      () => DioAuthRepository<UserModel>(
        dio: getIt<Dio>(instanceName: DiKey.authDio),
        tokenStore: getIt<TokenStore>(),
        config: _authConfig,
        userCache: getIt<JsonStore<UserModel>>(),
        settingsStore: SharedPrefsStore(getIt<SharedPreferences>()),
      ),
    )
    ..registerLazySingleton<PushRepository>(
      () => PushRepositoryImpl(
        getIt<PushRemoteDataSource>(),
        // In-memory current user id from the auth cubit (sync) — ADR-0019.
        () => getIt<AppAuthCubit>().state.user?.id,
      ),
    );
}
