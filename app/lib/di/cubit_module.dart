import 'package:get_it/get_it.dart';
import 'package:tasco_auth/tasco_auth.dart';
import 'package:tasco_core/tasco_core.dart';

import '../data/model/user_model.dart';
import '../features/auth/auth_cubit.dart';

Future<void> cubitModule(GetIt getIt) async {
  getIt.registerLazySingleton<AppAuthCubit>(
    () => AppAuthCubit(
      repository: getIt<AuthRepository<UserModel>>(),
      authEventBus: getIt<AuthEventBus>(),
      biometricService: DefaultBiometricService(),
    ),
  );
}
