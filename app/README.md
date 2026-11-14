# Shell App

Host app của **Tasco SuperApp** — điểm khởi động duy nhất, chịu trách nhiệm khởi tạo toàn bộ hệ thống, quản lý auth, và điều phối các mini-app.

---

## Cấu trúc thư mục

```
apps/shell/
├── assets/
│   ├── .env                  — env mặc định
│   ├── .env.development      — biến môi trường dev
│   ├── .env.staging          — biến môi trường staging
│   └── .env.production       — biến môi trường production
└── lib/
    ├── main_development.dart     — entry point dev
    ├── main_staging.dart         — entry point staging
    ├── main_production.dart      — entry point production
    ├── bootstrap.dart            — khởi tạo hệ thống (DI, modules, router)
    ├── app/
    │   └── app.dart              — MaterialApp.router + theme + l10n + ScreenUtil
    ├── core/
    │   ├── config/
    │   │   ├── env.dart          — enum Env (development/staging/production)
    │   │   ├── app_env.dart      — AppEnv helper
    │   │   └── loading_config.dart — EasyLoading setup
    │   ├── routing/
    │   │   ├── app_router.dart   — buildAppRouter() — gộp routes host + modules
    │   │   └── app_routes.dart   — route path constants
    │   ├── api/interceptors/
    │   │   ├── auth_interceptor.dart    — gắn Bearer token, xử lý 401
    │   │   ├── error_interceptor.dart   — xử lý lỗi tập trung
    │   │   └── logging_interceptor.dart — log request/response (dev only)
    │   ├── base/
    │   │   ├── loading_status.dart  — enum LoadingStatus
    │   │   └── loading_manager.dart
    │   └── notification/
    │       └── notification_director.dart — route push notification → module
    ├── di/                        — DI modules của host
    │   ├── di.dart                — setupDi() + setUpCubit()
    │   ├── api_module.dart
    │   ├── local_module.dart      — TokenStore, JsonStore<UserModel>
    │   ├── remote_module.dart
    │   ├── repository_module.dart
    │   ├── use_case_module.dart
    │   └── cubit_module.dart      — AuthCubit
    ├── data/model/
    │   ├── user_model.dart        — implements TascoAuthUser
    │   └── request/login_request.dart
    └── features/
        ├── splash/        — SplashPage (khởi tạo session)
        ├── auth/          — AuthCubit, AuthState, LoginPage
        ├── main_shell/    — MainShellPage (bottom nav + PreloadPageView)
        └── home/          — HomeDashboardPage
```

> Contract mini-app (`ModuleManager` / `ModuleSlot` / `ModuleNotification`) nằm ở package **`tasco_module`** (`package:tasco_module/tasco_module.dart`), không còn trong shell.

---

## Cách chạy app

### Yêu cầu

- Flutter SDK — dùng `fvm` (Flutter Version Manager)
- Dart SDK `^3.11.0`

### Cài dependencies

```bash
# Từ thư mục apps/shell
flutter pub get

# Hoặc dùng fvm
fvm flutter pub get
```

> Vì shell dùng local path dependencies (`ui_kit`, `core`, `tasco_mini_app`), cần chạy `pub get` ở root workspace trước nếu dùng melos/workspace, hoặc chạy lần lượt từng package.

### Chạy theo môi trường

```bash
# Development
flutter run -t lib/main_development.dart

# Staging
flutter run -t lib/main_staging.dart

# Production
flutter run -t lib/main_production.dart

# Chỉ định device
flutter run -t lib/main_development.dart -d <device-id>

# Liệt kê devices
flutter devices
```

### Build APK / IPA

```bash
# APK release
flutter build apk --release -t lib/main_production.dart

# App Bundle (upload Play Store)
flutter build appbundle --release -t lib/main_production.dart

# iOS
flutter build ios --release -t lib/main_production.dart
cd ios && pod install && cd ..
```

### Các lệnh thường dùng

```bash
# Phân tích code
flutter analyze

# Chạy tests
flutter test

# Clean + pub get (khi deps thay đổi hoặc build lỗi)
flutter clean && flutter pub get

# Sinh l10n (sau khi sửa file .arb trong lib/l10n/arb)
flutter gen-l10n
```

---

## Luồng khởi động

```
main_*.dart  →  bootstrap(env)
                  │
                  ├── 1. WidgetsFlutterBinding.ensureInitialized()
                  ├── 2. setupDi(env)          — đăng ký DI: API, storage, repo, use case
                  ├── 3. setUpCubit()           — đăng ký AuthCubit vào GetIt
                  ├── 4. configLoading()        — cấu hình EasyLoading
                  ├── 5. ModuleManager.register()  — đăng ký tất cả mini-app
                  ├── 6. moduleManager.initAll()   — init từng module theo thứ tự
                  ├── 7. buildAppRouter()           — gộp routes host + modules
                  └── 8. runApp(App)
```

---

## Routing

GoRouter với `initialLocation: /home`.

| Path | Widget | Mô tả |
|------|--------|-------|
| `/splash` | `SplashPage` | Khởi tạo session, redirect sau khi check auth |
| `/home` | `MainShellPage` | Shell chính với bottom nav |
| `/mini_app/*` | Routes từ `TascoMiniAppController` | Tất cả màn của mini-app |

Routes của mini-app được gộp tự động qua `moduleManager.collectRoutes()` — không cần khai báo thủ công.

```dart
// buildAppRouter — gộp routes
GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: '/splash', ...),
    GoRoute(path: '/home', ...),
    ...moduleManager.collectRoutes(),  // routes từ tất cả module đã đăng ký
  ],
)
```

---

## Auth Flow

`AuthCubit` (đăng ký trong GetIt) quản lý session toàn app:

| Method | Mô tả |
|--------|-------|
| `initSession()` | Gọi khi mở app — kiểm tra token, restore user từ cache, sync từ server |
| `login(username, password)` | Đăng nhập, lưu token + user info |
| `getUserInfo()` | Fetch user mới nhất từ server → lưu storage → emit state |
| `logout()` | Xóa token + user, emit unauthenticated |
| `isAuthenticated` | `true` khi `state.user != null` |

```dart
// Lắng nghe auth state trong widget
BlocBuilder<AuthCubit, AuthState>(
  builder: (context, state) {
    if (state.isAuthenticated) return HomeWidget();
    return LoginPage();
  },
)

// Gọi login
context.read<AuthCubit>().login(username: 'user', password: 'pass');

// Gọi logout
context.read<AuthCubit>().logout();
```

`AuthInterceptor` tự động gắn `Authorization: Bearer <token>` vào mọi request Dio và được inject vào tất cả mini-app khi đăng ký — mini-app không tự quản lý token.

---

## Bottom Navigation

`MainShellPage` dùng `PreloadPageView` — 4 tab được preload sẵn khi app mở, không rebuild khi switch tab:

| Index | Label | Icon | Widget |
|-------|-------|------|--------|
| 0 | Home | `Icons.home` | `HomeDashboardPage` |
| 1 | Explore | `Icons.explore` | placeholder |
| 2 | Notification | `Icons.notifications` | placeholder |
| 3 | Profile | `Icons.person` | placeholder |

Switch tab bằng `AppShellController`:

```dart
_shellController.selectTab(2);  // chuyển sang tab Notification
```

---

## Theme Tokens

Shell là owner của `TascoApp`, `ThemeMode`, `ColorScheme` và mọi `ThemeExtension`. Theme hiện tại
được truyền tại `lib/app/app.dart` qua `AppTheme.v1` và `AppTheme.v1Dark`. Khi cần bộ token mới,
không tạo `MaterialApp` trong feature hoặc mini-app:

1. Tạo factory light/dark trong `lib/core/theme/` từ `AppTheme.v1`/`AppTheme.v1Dark`.
2. Lấy `TascoThemeExtension` từ base preset, gọi `copyWith`, rồi cài lại nó trong `extensions`.
3. Thêm `ShellThemeTokens` riêng cho token chỉ thuộc shell.
4. Truyền hai preset vào `TascoApp`; feature đọc `context.tasco`, `ColorScheme` hoặc extension shell.

```dart
final base = AppTheme.v1;
final uiKitTokens = base.extension<TascoThemeExtension>()!;

final theme = base.copyWith(
  extensions: [
    uiKitTokens.copyWith(cardRadius: 16, spacingPage: 28),
    const ShellThemeTokens(/* shell-only roles */),
  ],
);
```

`ThemeData.copyWith(extensions: ...)` thay thế danh sách cũ, nên bắt buộc cài lại
`TascoThemeExtension`. Không thêm token nghiệp vụ vào UI kit. Xem developer guide
[`theme-tokens.md`](../../documents/docs/packages/theme-tokens.md) cho implementation `copyWith`/
`lerp`, dark parity và test strategy.

---

## Cách thêm mini-app mới

**Khuyến nghị — dùng CLI** (tự tạo package `mini_apps/<name>` + wire vào `pubspec.yaml` & `bootstrap.dart`):

```bash
# chạy ở thư mục gốc super app
tasco generate miniapp <name>
```

CLI chèn `import` + `register(...)` tại anchor `// tasco:miniapp-imports` và `// tasco:miniapp-register` trong `bootstrap.dart`.

**Thủ công** (khi cần): tạo package mini-app expose một controller có `toModuleSlot()` (xem `apps/mini_app` làm mẫu), rồi:

1. Thêm dependency vào `pubspec.yaml`:
   ```yaml
   dependencies:
     your_module:
       path: ../mini_apps/your_module   # trong repo này: ../<name> dưới apps/
   ```
2. Đăng ký trong `bootstrap.dart` (`ModuleSlot` đến từ `package:tasco_module/tasco_module.dart`) —
   đúng dòng CLI sinh ra; `env` là flavor của host, không có mặc định:
   ```dart
   import 'package:your_module/your_module.dart';

   moduleManager.register(
     YourController.instance.toModuleSlot(
       hostInterceptor: GetIt.I<AuthInterceptor>(),
       env: switch (env) {
         Env.development => .development,
         Env.staging => .staging,
         Env.production => .production,
       },
     ),
   );
   ```
3. Nếu mini-app có i18n, gắn `localizationsDelegates` của nó vào `App(miniAppDelegates: ...)`.

---

## Cấu hình môi trường (.env)

Các biến môi trường được load qua `flutter_dotenv` từ `assets/`:

| File | Dùng khi |
|------|----------|
| `.env.development` | `main_development.dart` |
| `.env.staging` | `main_staging.dart` |
| `.env.production` | `main_production.dart` |

Khai báo biến và truy cập:

```dart
// assets/.env.development
API_BASE_URL=https://dev-api.example.com
APP_NAME=Tasco Dev

// Trong code
final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
```

Key shell đang đọc (`AppEnv`, danh sách đồng bộ với `template.manifest.yaml › env.keys`):

| Key | Dùng cho | Để trống |
|-----|----------|----------|
| `AUTH_URL`, `CRM_URL`, `HRM_URL`, `TICKET_URL` | base URL từng Dio client | request fail vì base URL rỗng |
| `CERT_PINS` | SHA-256 pin, phân tách bằng dấu phẩy | không pin |
| `AUTH_CLIENT_ID` | `clientId` trong body đăng nhập | không gửi `clientId` |
| `CLIENT_SOURCE` | header `client_source` | không gửi header |

`X-App-Version` và `X-Device-Info` không nằm trong `.env`: version lấy từ bản cài
(`package_info_plus`), `deviceId` là UUID sinh ở lần chạy đầu và lưu trong SharedPreferences
(`ClientIdentity`).

---

## Dependencies chính

| Package | Mục đích |
|---------|---------|
| `flutter_bloc` | State management (Cubit) |
| `get_it` | Service locator / DI |
| `dio` | HTTP client |
| `go_router` | Declarative routing |
| `flutter_secure_storage` | Lưu token an toàn |
| `shared_preferences` | Lưu user info |
| `firebase_core` / `firebase_messaging` | Push notification |
| `firebase_crashlytics` | Crash reporting |
| `firebase_remote_config` | Remote config (prod URLs) |
| `flutter_dotenv` | Biến môi trường theo env |
| `preload_page_view` | Bottom nav không rebuild |
| `flutter_easyloading_plus` | Global loading overlay |
| `flutter_screenutil_plus` | Responsive sizing (design 393×852) |
| `ui_kit` | Design system nội bộ |
| `core` | Utilities nội bộ |
| `tasco_module` | Contract mini-app (ModuleSlot/Manager/Notification) |
| `tasco_mini_app` | Mini-app module mẫu (path `../mini_app`) |
