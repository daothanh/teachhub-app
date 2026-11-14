import 'package:get_it/get_it.dart';

import 'package:tasco_core/tasco_core.dart';
import 'api_module.dart';
import 'cubit_module.dart';
import 'local_module.dart';
import 'remote_module.dart';
import 'repository_module.dart';

Future<void> setupDi({required Env env}) async {
  await localModule(GetIt.I, env: env);
}

Future<void> setUpCubit() async {
  await apiModule(GetIt.I);
  await remoteModule(GetIt.I);
  await repositoryModule(GetIt.I);
  await cubitModule(GetIt.I);
}
