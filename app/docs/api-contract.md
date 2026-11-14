# Hợp đồng API mà app đang dùng

Các dạng dưới đây là những gì app hiện gửi và đọc. Khi backend triển khai, phải khớp
đúng các dạng này, hoặc sửa app cùng lúc. Base URL: `TEACHHUB_API_URL`, đã gồm `/v1`.

| Gọi | Body gửi | Phản hồi app đọc |
| --- | --- | --- |
| `POST /auth/otp/send` | `{ email }` | — |
| `POST /auth/login` | `{ method: "email_otp", email, code }` | `{ access_token, refresh_token, expires_in, user }` |
| `POST /auth/sso/google` | `{ id_token }` | như `/auth/login` |
| `POST /auth/sso/apple` | `{ id_token, nonce }` (nonce gốc; Apple nhận SHA-256) | như `/auth/login` |
| `POST /auth/refresh` | `{ refresh_token }` | `{ access_token, refresh_token? }` |
| `GET /auth/me` | — | `user` |
| `POST /auth/logout` | — | — |
| `GET /me/memberships` | — | `{ items: [{ id, role, label, tenantId?, studentId? }], lastMembershipId? }` |
| `PUT /me/active-membership` | `{ membershipId }` | — |
| `POST /workspaces` | `{}` | — (app tải lại memberships) |
| `POST /me/roles` | `{ role: "parent" \| "student" }` | — |
| `POST /invites/{token}/accept` | — | `{ membershipId }`; lỗi `CONSENT_REQUIRED` kèm `details.termsVersion` |
| `POST /consents` | `{ role: "parent", termsVersion }` | — |
| `POST /push/register`, `/push/unregister` | theo `tasco_notifications`: `{ userId, deviceToken, platform }` | — |

`user` = `{ id, email, displayName?, permissions: ["role:tenant_owner", …] }`.
`role` ∈ `tenant_owner | parent | student`. Vai trò lạ sẽ bị app bỏ qua.

Tên trường token/SSO dùng snake_case (`access_token`, `id_token`) vì `tasco_auth` cố định
như vậy (spec §2.11 G1). Các trường còn lại dùng camelCase.

Header app gửi kèm mọi request: `x-request-id`, `x-client-info: teachhub-app/<ver> (<os>)`;
thêm `Idempotency-Key` (UUID, giữ nguyên khi retry) cho mọi POST/PATCH. Lỗi đọc dạng
`{ code, message, … }` (spec §5.6).
