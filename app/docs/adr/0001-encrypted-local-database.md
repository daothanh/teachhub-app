# ADR-0001 (TeachHub app): Mã hóa CSDL cục bộ của mini-app `teacher`

- Trạng thái: Accepted · 14/11/2026
- Liên quan: Technical Spec v2.1 §6.4 (mục 7), §2.11 G8; ADR-0023 của app framework core

## Bối cảnh

Điểm danh ngoại tuyến là P0 (NFR-17). Cache ngoại tuyến chứa tên học sinh (PII),
mà ADR-0023 của framework cấm đưa PII vào SQLite khi chưa có ADR mã hóa.

Spec ghi "Drift + SQLCipher (`sqlcipher_flutter_libs`)". Từ drift 2.32,
`sqlcipher_flutter_libs` không còn cần: gói `sqlite3` đóng gói SQLite qua build hook
và có thể đóng gói **SQLite3MultipleCiphers** (sqlite3mc) thay SQLite gốc.

## Quyết định

1. Mini-app `teacher` sở hữu CSDL `teacher.sqlite` (Drift), mở qua
   `TeacherDatabase.openEncrypted` (`mini_apps/teacher/lib/data/local_db/`).
2. Mã hóa bằng sqlite3mc, bật bằng `hooks.user_defines.sqlite3.source: sqlite3mc`
   trong pubspec **của app host** (gốc của lần build) và của mini-app (cho test).
   Đây là thay đổi so với chữ "SQLCipher" trong spec: cùng mục tiêu (mã hóa toàn
   file, khóa 256-bit), khác thư viện.
3. Khóa: 32 byte từ `Random.secure()`, dạng hex, sinh ở lần mở đầu và lưu trong
   `SecureStore` (Keychain/Keystore) với tên `teacher.db_key`; đặt bằng
   `PRAGMA hexkey` trước mọi truy vấn.
4. Bản SQLite không có mã hóa (`PRAGMA cipher` rỗng) ⇒ ném lỗi và không mở, kể
   cả bản release (không dùng `assert`).
5. CSDL mở lười (đăng ký `registerLazySingletonAsync` trong `TeacherController.init`):
   người dùng không có vai trò Giáo viên không tạo file.
6. Chỉ lưu cột tối thiểu (tên, trạng thái — không SĐT, ngày sinh). Token không
   bao giờ vào SQLite.

## Cổng kiểm tra (theo ADR-0023)

| Cổng | Trạng thái |
| --- | --- |
| File không đọc được khi thiếu/sai khóa; không còn chuỗi plaintext | Có test (`test/data/teacher_database_test.dart`) |
| `client_mutation_id` duy nhất trong outbox | Có test |
| Export schema | `drift_schemas/drift_schema_v1.json` (`dart run drift_dev schema dump …`) |
| Build Android/iOS với sqlite3mc | Kiểm khi build app (xem README) |
| Giữ dữ liệu sau khởi động lại, test mọi đường nâng cấp schema, kiểm codegen trong CI | **Chưa** — làm cùng SyncEngine và migration v2 |

## Chưa làm (việc của sprint điểm danh)

- SyncEngine, `workmanager` (đẩy outbox khi chạy nền), `connectivity_plus` (banner
  "Ngoại tuyến" T03/T04).
- Xóa CSDL khi đăng xuất sau khi outbox trống; cảnh báo "Còn N buổi chưa đồng bộ".

## Hệ quả

- Mọi lệnh `flutter build/run/test` của app tải và biên dịch sqlite3mc qua build hook.
- Đổi tên khóa `teacher.db_key` hoặc mất Keychain ⇒ không mở được CSDL cũ; khi đó xóa
  file và tải lại từ server (dữ liệu nguồn ở server, trừ outbox chưa đồng bộ).
