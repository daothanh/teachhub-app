import 'package:get_it/get_it.dart';
import 'package:tasco_core/tasco_core.dart';

import 'api_module.dart';
import 'cubit_module.dart';
import 'local_module.dart';
import 'remote_module.dart';
import 'repository_module.dart';

/// local → api → remote → repository → cubit (spec §8.3).
Future<void> setupDi({required Env env}) async {
  final getIt = GetIt.I;
  await localModule(getIt, env: env);
  await apiModule(getIt);
  await remoteModule(getIt);
  await repositoryModule(getIt);
  await cubitModule(getIt);
}
