import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasco_core/tasco_core.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../core/config/app_env.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/teachhub_user.dart';
import '../l10n/l10n.dart';

const _localeKey = 'app_locale';
const _userKey = 'user_info';

Future<void> localModule(GetIt getIt, {required Env env}) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  final appEnv = await AppEnv.load(env);
  final packageInfo = await PackageInfo.fromPlatform();

  getIt
    ..registerSingleton<SharedPreferences>(sharedPrefs)
    ..registerSingleton<AppEnv>(appEnv)
    ..registerSingleton<PackageInfo>(packageInfo)
    // Token chỉ nằm ở Keychain/Keystore (spec §2.2).
    ..registerLazySingleton<TokenStore>(() => TokenStore(SecureStore()))
    // User đã lưu để khôi phục phiên nhanh (tasco_auth userCache).
    ..registerLazySingleton<JsonStore<TeachHubUser>>(
      () => JsonStore<TeachHubUser>(
        store: SharedPrefsStore(sharedPrefs),
        key: _userKey,
        fromJson: TeachHubUser.fromJson,
        toJson: (u) => u.toJson(),
      ),
    )
    ..registerLazySingleton<LoadingManager>(() => LoadingManager())
    ..registerLazySingleton<AuthEventBus>(() => AuthEventBus())
    // Vai trò đang mở — mini-app đọc qua teachhub_shared.
    ..registerSingleton<ActiveMembership>(ActiveMembership(null))
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
    ..registerLazySingleton<ThemeController>(
      () => ThemeController(sharedPrefs),
    );
}
