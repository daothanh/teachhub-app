# Cấu hình native (Android / iOS)

## Flavor

| Flavor | Entrypoint | Android applicationId | iOS bundle id | Tên app |
|---|---|---|---|---|
| `development` | `lib/main_development.dart` | `vn.com.tasco.teachhub.dev` | `vn.com.tasco.teachhub.dev` | TeachHub Dev |
| `staging` | `lib/main_staging.dart` | `vn.com.tasco.teachhub.stg` | `vn.com.tasco.teachhub.stg` | TeachHub Stg |
| `production` | `lib/main_production.dart` | `vn.com.tasco.teachhub` | `vn.com.tasco.teachhub` | TeachHub |

```sh
flutter run --flavor development -t lib/main_development.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter build appbundle --flavor production -t lib/main_production.dart
flutter build ipa --flavor production -t lib/main_production.dart
```

Luôn truyền `--flavor`: iOS chỉ có scheme `development` / `staging` / `production`
(build configuration `Debug-<flavor>`, `Release-<flavor>`, `Profile-<flavor>`).
Sau khi đổi Podfile/cấu hình, chạy lại `cd ios && pod install`.

Tối thiểu: Android 9 (API 28), iOS 15.0.

## Ký bản release Android

Tạo `android/key.properties` (đã gitignore, không commit; keystore `*.jks`/`*.keystore` cũng bị ignore):

```properties
# storeFile: đường dẫn tương đối với android/app/ (hoặc tuyệt đối)
storeFile=../upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Thiếu file này thì mọi build release (`assemble*Release`, `bundle*Release`) dừng với lỗi rõ ràng;
debug/profile vẫn chạy bình thường. Release không bao giờ ký bằng debug key.

HTTP không mã hoá (cleartext) chỉ bật ở debug (`android/app/src/debug/AndroidManifest.xml`).

## Firebase (FCM, Crashlytics, Remote Config)

- Android: `android/app/src/<flavor>/google-services.json`
  (ví dụ `android/app/src/development/google-services.json`). Plugin Google Services và
  Crashlytics chỉ được apply khi có ít nhất một file; khi đã apply thì flavor nào thiếu file sẽ build lỗi.
- iOS: `ios/config/<flavor>/GoogleService-Info.plist`. Build phase
  "Copy GoogleService-Info.plist" chép file đúng flavor vào app bundle; thiếu file chỉ in warning.

## Google Sign-In (iOS)

Mỗi flavor có bundle id riêng nên cần iOS OAuth client riêng. Điền 2 build setting của target
Runner cho từng configuration `*-<flavor>` (Xcode → Runner → Build Settings → User-Defined):

- `GOOGLE_CLIENT_ID` = `CLIENT_ID` trong GoogleService-Info.plist (`xxxx.apps.googleusercontent.com`)
- `GOOGLE_REVERSED_CLIENT_ID` = `REVERSED_CLIENT_ID` (`com.googleusercontent.apps.xxxx`)

Info.plist dùng chúng cho `GIDClientID` và URL scheme callback. Để trống thì build vẫn chạy
nhưng đăng nhập Google trên iOS sẽ không hoạt động. Android dùng SHA-1/SHA-256 của keystore
(debug + upload + Play App Signing) đăng ký trong Firebase/Google Cloud.

## Sign in with Apple, deep link, universal/app link

- Entitlements: `ios/Runner/Runner.entitlements` (`applinks:teachhub.vn`, Sign in with Apple).
  App ID trên Apple Developer phải bật Associated Domains và Sign in with Apple cho cả 3 bundle id.
- Deep link: `teachhub://...` (Android + iOS).
- Universal/App link: `https://teachhub.vn/i/<token>`. Web app teachhub.vn phải phục vụ:
  - `https://teachhub.vn/.well-known/apple-app-site-association` (appID `<TEAM_ID>.vn.com.tasco.teachhub[.dev|.stg]`, path `/i/*`)
  - `https://teachhub.vn/.well-known/assetlinks.json` (package name từng flavor + SHA-256 của chứng chỉ ký)

## Push (iOS)

`Runner.entitlements` có `aps-environment = development` và Info.plist bật
`UIBackgroundModes: remote-notification`. Khi archive/export bản App Store, Xcode lấy giá trị
`production` từ provisioning profile. App ID của cả 3 bundle id cần bật Push Notifications,
Associated Domains và Sign in with Apple; upload APNs key lên Firebase.

## Deep link

`app_links` + `TeachHubDeepLinkResolver` xử lý link, nên cơ chế deep link mặc định của Flutter
đã tắt (`FlutterDeepLinkingEnabled = false`, `flutter_deeplinking_enabled = false`).
