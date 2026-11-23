# TeachHub app — host shell

> Đóng băng từ 23/11/2026: app mobile chuyển sang native (`../native`, ADR `TeachHub-ADR-Native-Mobile.md`, D25). Thư mục này chỉ nhận sửa lỗi chặn việc kiểm thử, không thêm tính năng, và sẽ bị xóa ở NA-13.

App Flutter của TeachHub trên app framework core (`tasco_*` 5.2.x). Đây là super app gồm
host shell và một mini-app cho mỗi vai trò (Technical Spec v2.1 §3.7, §8.3).

```
teachhub-app/
├── app/                      # host shell (thư mục này)
├── mini_apps/
│   ├── teacher/              # /t — Giáo viên (sở hữu CSDL ngoại tuyến mã hóa)
│   ├── parent/               # /p — Phụ huynh
│   └── student/              # /s — Học sinh
└── packages/teachhub_shared/ # DiKey, route, Membership dùng chung
```

## Shell gồm gì

Shell chỉ làm phần ghép nối, không chứa luật nghiệp vụ:

| Phần | File |
| --- | --- |
| Bootstrap (Firebase, DI, mini-app, router, push, deep link, OTA) | `lib/bootstrap.dart` |
| Cấu hình theo flavor (`assets/.env.<flavor>`) | `lib/core/config/app_env.dart` |
| Một `Dio` cho TeachHub API, một cho R2 presigned | `lib/di/api_module.dart` |
| Header `x-request-id`, `x-client-info`, `Idempotency-Key` | `lib/core/network/teachhub_headers_interceptor.dart` |
| Đăng nhập email OTP, Google, Apple (T01, T01a) | `lib/features/auth/` |
| Vai trò: tải, chọn, thêm (T01c, T00) | `lib/features/role_picker/` |
| Nhận lời mời `dayhoc.app/i/<token>` | `lib/features/invite/`, `lib/core/deep_link/` |
| Router và guard (đăng nhập → vai trò → quyền theo vai trò) | `lib/core/routing/app_router.dart` |

## Chạy

Luôn truyền `--flavor`, vì mỗi flavor chỉ đóng gói file `.env` của chính nó.

```bash
flutter pub get
flutter run --flavor development -t lib/main_development.dart
```

- Development trỏ tới backend local `http://10.0.2.2:3000/v1` (Android emulator). Với iOS
  simulator, sửa thành `http://localhost:3000/v1` trong `assets/.env.development`.
- Staging và production **dừng ngay khi khởi động** nếu thiếu cấu hình Firebase của flavor đó.
  Cách thêm file Firebase, ký release, Google client ID: xem `docs/native-setup.md`.
- Hợp đồng API: `teachhub-backend/contracts/openapi.json` (nguồn duy nhất). Bản chép dùng cho test nằm ở
  `packages/teachhub_shared/contracts/`, cập nhật bằng `dart run tool/sync_openapi.dart`.

Mini-app teacher đọc danh bạ (`flutter_contacts`) nên quyền khai ở shell: `NSContactsUsageDescription` trong
`ios/Runner/Info.plist` và `READ_CONTACTS` trong `android/app/src/main/AndroidManifest.xml`.

## Kiểm tra

```bash
flutter analyze && flutter test
```

Mỗi package trong `mini_apps/*` và `packages/teachhub_shared` có bộ test riêng (`flutter test`
trong thư mục package đó). Sau khi sửa bảng Drift trong `mini_apps/teacher`, chạy:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Quyết định kiến trúc

- `docs/adr/0001-encrypted-local-database.md`: CSDL cục bộ mã hóa bằng SQLite3MultipleCiphers.
