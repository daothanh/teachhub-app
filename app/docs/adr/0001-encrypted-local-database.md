# ADR-0001 (TeachHub app): Mã hóa CSDL cục bộ của mini-app `teacher`

- Trạng thái: Accepted · 14/11/2026 · cập nhật số đo máy thật 18/11/2026
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
| Export schema | `drift_schemas/drift_schema_v1.json` đến `drift_schema_v3.json` (`dart run drift_dev schema dump …`) |
| Nâng cấp schema v1 → v2 | **Đạt** — `test/data/teacher_migration_test.dart`: `SchemaVerifier` khớp schema v2; nâng cấp trên **file mã hóa** có dữ liệu v1 → dữ liệu còn, cột mới có mặc định |
| Build + chạy trên máy Android thật | **Đạt** 18/11/2026 — OPPO CPH2577 (Android 13, tầm trung), `app/integration_test/teacher_db_device_test.dart` |
| File trên máy đã mã hóa | **Đạt** — 16 byte đầu là dữ liệu ngẫu nhiên, không phải `SQLite format 3` |
| Ghi 20 bản ghi điểm danh < 100 ms | **Đạt với `batch`**: trung vị 14,8–18,4 ms, tối đa 21,5 ms (2 lần chạy × 10 lần đo). 20 lệnh `insert` riêng trong một giao dịch: trung vị 93–102 ms, tối đa 146 ms — **không đạt ổn định** vì mỗi lệnh là một lượt qua isolate của drift ⇒ lưu điểm danh **phải** dùng `batch`/`insertAll` |
| Giữ dữ liệu sau khởi động lại | **Đạt** — pha `read` chạy ở tiến trình mới, khóa đọc lại từ Keystore, đủ 441 bản ghi, schema v2 |
| Xóa CSDL (đăng xuất) | **Đạt** — `deleteTeacherDatabase` xóa `teacher.sqlite` (+ WAL/SHM/journal) và khóa `teacher.db_key`; có test máy tính và trên máy thật |
| Build + chạy trên iOS 15 (máy thật) | **Chưa** — chưa có iPhone; làm khi có máy + tài khoản Apple Developer (S0-PO-01) |
| Kiểm codegen Drift + export schema trong CI | **Chưa** — repo chưa có CI (S0-FL-05) |

Chạy lại số đo trên máy thật:

```sh
cd app
flutter test integration_test/teacher_db_device_test.dart -d <máy> \
  --flavor development --dart-define=PHASE=write --no-uninstall
flutter test integration_test/teacher_db_device_test.dart -d <máy> \
  --flavor development --dart-define=PHASE=read
```

`--no-uninstall` ở pha write là bắt buộc: mặc định `flutter test` gỡ app sau khi chạy test tích hợp, xóa luôn dữ liệu.

## Spike SyncEngine (S0-FL-08, 18/11/2026)

`mini_apps/teacher/lib/data/sync/sync_engine.dart`: đẩy outbox theo lô đúng thứ tự `id`;
`applied`/`duplicate`/`stale` → xóa khỏi outbox, `rejected` → giữ với
`lastError = rejected:<mã>` và không gửi lại; mất mạng/5xx/429 → tăng `attemptCount`,
thử lại sau 1s, 2s, 4s… tối đa 1 giờ; có mạng trở lại (`connectivity_plus`) → đẩy ngay.
Banner "Ngoại tuyến" ở trang gốc Giáo viên.

Ghi chú DoD trên OPPO CPH2577 (`app/integration_test/sync_engine_device_test.dart`,
endpoint giả là HttpServer trong app, "mất mạng" = server chưa mở):

| Bước | Kết quả |
| --- | --- |
| Mất mạng → lưu 25 mutation | Lưu xong (620 ms, gồm lần mở CSDL đầu tiên) |
| Chờ 4 s | Vẫn 25 mutation, `attemptCount = 3`, `lastError = network` |
| Bật mạng, lô đầu áp dụng xong nhưng **mất phản hồi** | Lô đó gửi lại, server trả `duplicate` cho cả 10 |
| Kết thúc | Outbox trống sau 4 request; server áp dụng đúng 25 mutation, không lần nào 2 lần |

Nhận xét: backoff tính theo `attemptCount` tích lũy, nên lỗi ngay sau khi có mạng lại chờ
lâu hơn (lần chạy trên chờ 8 s) — chấp nhận được vì sự kiện có mạng luôn kích hoạt đẩy ngay.

## Chưa làm (việc của sprint điểm danh)

- `workmanager` (đẩy outbox khi app chạy nền): chưa thêm ở spike — isolate nền phải tự
  dựng lại CSDL (khóa từ Keystore), token và Dio; làm cùng transport thật ở S3-FL-08.
- Transport thật (Dio `TeachHubDiKey.api`, `POST /v1/attendance/sync`, Idempotency-Key)
  và `stale` kéo bản của server về: S3-FL-08 sau hợp đồng S2-FL-10.
- Gọi `deleteTeacherDatabase` trong luồng đăng xuất sau khi outbox trống (S1-FL-10);
  cảnh báo "Còn N buổi chưa đồng bộ".

## Schema v3 và SyncEngine thật (S3-FL-08, S3-FL-10)

- v3 thêm bảng cache `cached_sessions` (buổi: id, lớp, ngày, giờ, trạng thái, `canEdit`, `editableUntil`) và
  `cached_attendances` (tên học viên, trạng thái, ghi chú, `clientUpdatedAt`) — chỉ cột tối thiểu, không SĐT, ngày sinh.
  Outbox có thêm `sessionId`, `studentId`, `batchKey`, `batchDeviceTime`. Dòng outbox cũ của spike v2 không có
  `sessionId` nên SyncEngine bỏ qua.
- Mỗi lô gửi lên server là một buổi, tối đa 500 mutation. `Idempotency-Key` và `deviceTime` của lô lưu ngay vào các
  dòng outbox khi gom lô, nên gửi lại sau khi mất phản hồi, kể cả sau khi app bị kill, là đúng cùng một request.
- 404 và 409 `SESSION_CANCELLED` cả lô: dòng chuyển `lastError = batch:<mã>`, không gửi lại. `stale`: ghi đè bản cục bộ
  bằng `current` trừ khi người dùng đã sửa tiếp. Banner phát qua `SyncEngine.events`, chip qua `watchPending()`.
- Xóa CSDL: `TeacherLocalData` dừng engine và chờ lượt đang chạy xong trước khi đóng CSDL, rồi bật lại sau khi mở lại.

## Hệ quả

- Mọi lệnh `flutter build/run/test` của app tải và biên dịch sqlite3mc qua build hook.
- Đổi tên khóa `teacher.db_key` hoặc mất Keychain ⇒ không mở được CSDL cũ; khi đó xóa
  file và tải lại từ server (dữ liệu nguồn ở server, trừ outbox chưa đồng bộ).
