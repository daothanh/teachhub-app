import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_notifications/tasco_notifications.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../features/auth/auth_config.dart';
import '../features/center_waitlist/center_waitlist_repository.dart';
import '../features/auth/auth_cubit.dart';
import '../features/auth/teachhub_user.dart';

Future<void> repositoryModule(GetIt getIt) async {
  getIt
    ..registerLazySingleton<AuthRepository<TeachHubUser>>(
      () => DioAuthRepository<TeachHubUser>(
        dio: getIt<Dio>(instanceName: TeachHubDiKey.api),
        tokenStore: getIt<TokenStore>(),
        config: teachHubAuthConfig,
        userCache: getIt<JsonStore<TeachHubUser>>(),
        settingsStore: SharedPrefsStore(getIt<SharedPreferences>()),
      ),
    )
    ..registerLazySingleton<CenterWaitlistRepository>(
      () => DioCenterWaitlistRepository(
        getIt<Dio>(instanceName: TeachHubDiKey.api),
      ),
    )
    ..registerLazySingleton<PushRepository>(
      () => PushRepositoryImpl(
        getIt<PushRemoteDataSource>(),
        () => getIt<AppAuthCubit>().state.user?.id,
      ),
    );
}
