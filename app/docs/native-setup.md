# Cấu hình native (Android / iOS)

## Flavor

| Flavor | Entrypoint | Android applicationId | iOS bundle id | Tên app |
|---|---|---|---|---|
| `development` | `lib/main_development.dart` | `vn.dayhoc.app.dev` | `vn.dayhoc.app.dev` | DayHoc Dev |
| `staging` | `lib/main_staging.dart` | `vn.dayhoc.app.stg` | `vn.dayhoc.app.stg` | DayHoc Stg |
| `production` | `lib/main_production.dart` | `vn.dayhoc.app` | `vn.dayhoc.app` | DayHoc |

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

Project (tài khoản Firebase của PO): `development` → `dayhoc-dev`, `staging` → `dayhoc-stg`,
`production` → `dayhoc-4c6db`. Tải lại config: `firebase apps:sdkconfig <ANDROID|IOS> <appId> --project <id>`.

- Android: `android/app/src/<flavor>/google-services.json`
  (ví dụ `android/app/src/development/google-services.json`). Plugin Google Services và
  Crashlytics chỉ được apply khi có ít nhất một file; khi đã apply thì flavor nào thiếu file sẽ build lỗi.
- iOS: `ios/config/<flavor>/GoogleService-Info.plist`. Build phase
  "Copy GoogleService-Info.plist" chép file đúng flavor vào app bundle; thiếu file chỉ in warning.

### Việc Owner cần làm để bật push (S3-FL-04)

Repo chưa có file cấu hình Firebase vì phải tạo trên console; agent không tạo project/app Firebase.
Flavor `development` chạy được khi thiếu file: `bootstrap` ghi một dòng cảnh báo
(`Firebase chưa cấu hình: bỏ qua đăng ký và nhận push`) và không đăng ký push. Staging/production dừng khi khởi động.

1. Tạo app Android + iOS cho từng flavor trong project Firebase tương ứng (bảng trên), đúng applicationId/bundle id.
2. Đặt `google-services.json` và `GoogleService-Info.plist` vào đúng đường dẫn ở trên (đã gitignore, không commit).
3. Upload APNs key (Auth Key `.p8`) lên Firebase Cloud Messaging của từng project; bật Push Notifications cho 3 App ID.
4. Android 13+: quyền `POST_NOTIFICATIONS` khai trong `AndroidManifest.xml`; hộp thoại xin quyền hiện qua banner "bật thông báo" của P02.
5. Thử trên máy thật: xem mục "Thử push trên máy thật" bên dưới.

### iOS: entitlements theo cấu hình build

`aps-environment` khác nhau theo môi trường APNs nên có hai file trong `ios/Runner/`:

| File | Cấu hình build | `aps-environment` |
|---|---|---|
| `Runner.entitlements` | `Debug-*`, `Profile-*` (cả 3 flavor) | `development` |
| `RunnerRelease.entitlements` | `Release-*` | `production` |

`Profile` ký bằng provisioning development nên dùng `development`. Cả hai giữ nguyên `applinks:dayhoc.app` và Sign in with Apple. `CODE_SIGN_ENTITLEMENTS` trỏ theo từng build configuration
trong `project.pbxproj`. Kiểm nhanh:
`xcodebuild -showBuildSettings -project ios/Runner.xcodeproj -target Runner -configuration Release-staging | grep ENTITLEMENTS`.

### Android: kênh thông báo

Lúc khởi động app tạo 3 kênh (tên theo ngôn ngữ app, vi/en): `attendance` (quan trọng cao), `billing`, `general`.
Biểu tượng thông báo là `ic_stat_notification` (chữ D đơn sắc), màu `brand_logo`. Backend gửi `channelId` thuộc nhóm này; tin không khai kênh rơi vào `general` nhờ
`com.google.firebase.messaging.default_notification_channel_id` trong `AndroidManifest.xml`.

### Hiển thị và chạm thông báo

Backend gửi FCM có khối `notification` (tiêu đề, nội dung) cùng `data {notificationId, type}`.

- App nền hoặc đã tắt: hệ điều hành tự vẽ; chạm → `onMessageOpenedApp` / `getInitialMessage` → `PushNavigator`.
- App đang mở, iOS: bật presentation options (alert, badge, sound), hệ thống tự vẽ; chạm đi cùng đường trên.
- App đang mở, Android: `ForegroundNotifications` (`lib/core/push/`) vẽ bằng `flutter_local_notifications` đúng kênh;
  chạm → `PushNavigator`.

### Thử push trên máy thật

1. Đăng nhập app (flavor có Firebase), kiểm `POST /push/register` thành công.
2. Firebase console → Messaging → tạo thông báo thử, dán FCM token của máy; ở "Custom data" thêm `type` = `student_absent`
   (hoặc `invoice_issued`, `billing_ready`) và `notificationId` bất kỳ.
3. Thử ba trạng thái: app đang mở, ở nền, đã tắt hẳn. Cả ba chạm vào đều phải mở đúng màn (`student_absent` → `/p`, tự đổi sang vai trò Phụ huynh).
4. Đăng xuất → `POST /push/unregister`; gửi lại không còn nhận.

iOS cần máy thật (simulator không nhận APNs); bản Debug dùng APNs sandbox, bản Release/TestFlight dùng production.

## Đồng bộ nền (S3-FL-09)

- Android: `workmanager` (WorkManager) hẹn một tác vụ một-lần `vn.dayhoc.app.sync-outbox`, ràng buộc có mạng. Không cần khai thêm
  trong `AndroidManifest.xml` (plugin tự gộp).
- iOS: `BGProcessingTask` cùng định danh. `Info.plist` khai `UIBackgroundModes: processing` và
  `BGTaskSchedulerPermittedIdentifiers` (`vn.dayhoc.app.sync-outbox`); `AppDelegate.swift` gọi
  `WorkmanagerPlugin.registerLaunchHandlers()` và `setPluginRegistrantCallback`. Không cần bật thêm capability trong Apple Developer.
- iOS quyết định lúc nào chạy (không đảm bảo thời điểm). Thử bằng Xcode: Debug → Simulate Background Fetch, hoặc lệnh LLDB
  `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"vn.dayhoc.app.sync-outbox"]`.
- Callback nền chỉ chạy khi còn token đăng nhập; đăng xuất hoặc xóa dữ liệu thì hủy lịch.

## Google Sign-In

App dùng `google_sign_in` 7.x; `GoogleSsoProvider` lấy `id_token` rồi gọi `POST /v1/auth/sso/google` (body `{id_token}`).
`id_token` có audience = **Web client ID** của flavor (`serverClientId`, đặt trong `assets/.env.<flavor>` →
`GOOGLE_SERVER_CLIENT_ID`); backend phải chấp nhận audience này.

Client ID công khai (không phải secret), hậu tố `.apps.googleusercontent.com`:

| Flavor / project | Web (`serverClientId`, audience) | iOS | Android debug | Android upload |
|---|---|---|---|---|
| `development` / `dayhoc-dev` | `305225338991-7vf98anmjogm9jksgd9kdije4ah8ncgk` | `305225338991-eg6h9lb26na0br8qph3gaff5041dga2f` | `305225338991-r640djv4j04rhv3uqq8g4m56bs3n901a` | `305225338991-5m421cgrtvgf1flv3dhgu8i50uotj9n9` |
| `staging` / `dayhoc-stg` | `753323722874-khh3u3aobf813cib4l2m6bvotebld0q7` | `753323722874-o79dktgt6nnak8npj90nm114p1jv6aca` | `753323722874-at7jre1ehfam9pt140oar0d3k3dqbnd2` | `753323722874-hmhkvu7f1bkgm00mgjkv40k52hrs6pig` |
| `production` / `dayhoc-4c6db` | `432762025168-e2lo4mengjqb64e8bc2sdoat1vbqpdl8` | `432762025168-cp0i0crpa16la5fuudd95sbkfasc84tc` | `432762025168-3i1f3r2a7oelb9hg7pusr9uqc48umcdh` | `432762025168-jfmmmpogljjoilurl0t6i7m60d172e19` |

iOS: mỗi flavor có bundle id riêng. Hai build setting của target Runner (đã điền cho mọi configuration, theo bundle id):
`GOOGLE_CLIENT_ID` (= `CLIENT_ID` trong GoogleService-Info.plist) và `GOOGLE_REVERSED_CLIENT_ID` (= `REVERSED_CLIENT_ID`).
Info.plist dùng chúng cho `GIDClientID` và URL scheme callback. Cần đổi thì sửa trong Xcode → Runner → Build Settings → User-Defined.

Android: dùng `oauth_client` trong `google-services.json`; client Android khớp SHA-1 của keystore (debug, upload).
Chưa có client cho SHA của **Play App Signing**: thêm sau khi lên Play (Play Console → App integrity → SHA-1), đăng ký
trong Firebase rồi tải lại file; tới lúc đó bản cài từ Play có thể không đăng nhập Google được.

Lấy lại file cấu hình (sau khi thêm SHA/client trong Firebase):

```sh
firebase apps:list --project dayhoc-dev                     # lấy appId
firebase apps:sdkconfig IOS <iosAppId> --project dayhoc-dev       # → ios/config/<flavor>/GoogleService-Info.plist
firebase apps:sdkconfig ANDROID <androidAppId> --project dayhoc-dev  # → android/app/src/<flavor>/google-services.json
```

(bỏ các dòng tiến trình CLI in ở đầu khi ghi ra file). Project: `dayhoc-dev`, `dayhoc-stg`, `dayhoc-4c6db`.

Thử trên máy thật: `flutter run --flavor development -t lib/main_development.dart`, bấm "Tiếp tục với Google",
chọn tài khoản → app vào trang chính. Android cần máy có Google Play services và SHA-1 debug của máy build đã đăng ký
(`./gradlew signingReport`); iOS chạy được trên simulator hoặc máy thật.

## Sign in with Apple, deep link, universal/app link

- Entitlements: `ios/Runner/Runner.entitlements` (`applinks:dayhoc.app`, Sign in with Apple).
  App ID trên Apple Developer phải bật Associated Domains và Sign in with Apple cho cả 3 bundle id.
- Deep link: `teachhub://...` (Android + iOS).
- Universal/App link: `https://dayhoc.app/i/<token>`. Domain `dayhoc.app` (teachhub-web, Technical Spec A4) phải phục vụ:
  - `https://dayhoc.app/.well-known/apple-app-site-association` (appID `BACYKSGK57.vn.dayhoc.app[.dev|.stg]`, path `/i/*`)
  - `https://dayhoc.app/.well-known/assetlinks.json` (package name từng flavor + SHA-256 của chứng chỉ ký)

## Push (iOS)

`Runner.entitlements` có `aps-environment = development` và Info.plist bật
`UIBackgroundModes: remote-notification`. Khi archive/export bản App Store, Xcode lấy giá trị
`production` từ provisioning profile. App ID của cả 3 bundle id cần bật Push Notifications,
Associated Domains và Sign in with Apple; upload APNs key lên Firebase.

## Deep link

`app_links` + `TeachHubDeepLinkResolver` xử lý link, nên cơ chế deep link mặc định của Flutter
đã tắt (`FlutterDeepLinkingEnabled = false`, `flutter_deeplinking_enabled = false`).

## Chạy với mock API (Prism)

Mock trả ví dụ trong hợp đồng `teachhub-backend/contracts/openapi.json` — làm màn hình
trước khi API thật có (S0-FL-10).

```sh
# 1. Trong teachhub-backend
pnpm mock                                   # http://localhost:4010/v1

# 2a. Máy Android thật (USB): chuyển cổng máy → máy tính
adb reverse tcp:4010 tcp:4010
flutter run --flavor development -t lib/main_development.dart \
  --dart-define=TEACHHUB_API_URL=http://localhost:4010/v1

# 2b. Android emulator: http://10.0.2.2:4010/v1 · iPhone thật: http://<IP-LAN-máy-tính>:4010/v1
```

- `--dart-define=TEACHHUB_API_URL` chỉ ghi đè ở flavor development/staging; production luôn dùng `assets/.env.production`.
- HTTP thường (không TLS) chỉ được phép ở bản debug (Android `src/debug/AndroidManifest.xml`).
- Mock không giữ trạng thái: mã OTP nào đúng định dạng cũng đăng nhập được, dữ liệu là ví dụ cố định.
