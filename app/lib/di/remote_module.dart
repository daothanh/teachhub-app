import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:tasco_notifications/tasco_notifications.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

Future<void> remoteModule(GetIt getIt) async {
  getIt.registerLazySingleton<PushRemoteDataSource>(
    () => PushRemoteDataSource(getIt<Dio>(instanceName: TeachHubDiKey.api)),
  );
}
