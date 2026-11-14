import 'package:flutter/widgets.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_env.dart';
import '../core/config/client_identity.dart';
import '../core/theme/theme_controller.dart';
import '../data/model/user_model.dart';
import '../l10n/l10n.dart';

const _localeKey = 'app_locale';
const _userKey = 'user_info';

Future<void> localModule(GetIt getIt, {required Env env}) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  final appEnv = AppEnv();
  await appEnv.init(env);
  // Resolved before any Dio client exists, since every client sends it.
  final clientIdentity = await ClientIdentity.resolve(
    store: SharedPrefsStore(sharedPrefs),
    clientSource: appEnv.clientSource,
  );

  getIt
    ..registerLazySingleton<SharedPreferences>(() => sharedPrefs)
    ..registerLazySingleton<TokenStore>(() => TokenStore(SecureStore()))
    // Cached user for fast session restore (tasco_auth userCache).
    ..registerLazySingleton<JsonStore<UserModel>>(
      () => JsonStore<UserModel>(
        store: SharedPrefsStore(sharedPrefs),
        key: _userKey,
        fromJson: UserModel.fromStorageJson,
        toJson: (u) => u.toStorageJson(),
      ),
    )
    ..registerLazySingleton<AppEnv>(() => appEnv)
    ..registerLazySingleton<ClientIdentity>(() => clientIdentity)
    ..registerLazySingleton<LoadingManager>(() => LoadingManager())
    // Bus phiên xác thực — đăng ký sớm để AuthCubit/App subscribe được.
    ..registerLazySingleton<AuthEventBus>(() => AuthEventBus())
    // Locale runtime: khôi phục lựa chọn đã lưu; persist khi đổi (P2-11).
    ..registerLazySingleton<LocaleController>(() {
      final saved = sharedPrefs.getString(_localeKey);
      return LocaleController(
        supportedLocales: AppLocalizations.supportedLocales,
        initial: saved != null ? Locale(saved) : null,
        onChanged: (locale) => locale == null
            ? sharedPrefs.remove(_localeKey)
            : sharedPrefs.setString(_localeKey, locale.languageCode),
      );
    })
    // Theme mode: Light / Dark / System, persisted across restarts.
    ..registerLazySingleton<ThemeController>(() => ThemeController(sharedPrefs));
}
