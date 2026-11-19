import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../features/auth/auth_cubit.dart';
import '../features/auth/teachhub_user.dart';
import '../features/center_waitlist/center_waitlist_cubit.dart';
import '../features/center_waitlist/center_waitlist_repository.dart';
import '../features/role_picker/membership_cubit.dart';

Future<void> cubitModule(GetIt getIt) async {
  getIt
    ..registerLazySingleton<AppAuthCubit>(
      () => AppAuthCubit(
        repository: getIt<AuthRepository<TeachHubUser>>(),
        authEventBus: getIt<AuthEventBus>(),
        // Mở khóa chế độ phụ huynh bằng sinh trắc học (US-0.5).
        biometricService: DefaultBiometricService(),
      ),
    )
    ..registerFactory<CenterWaitlistCubit>(
      () => CenterWaitlistCubit(getIt<CenterWaitlistRepository>()),
    )
    ..registerLazySingleton<MembershipCubit>(
      () => MembershipCubit(
        api: getIt<Dio>(instanceName: TeachHubDiKey.api),
        prefs: getIt<SharedPreferences>(),
        activeMembership: getIt<ActiveMembership>(),
      ),
    );
}
