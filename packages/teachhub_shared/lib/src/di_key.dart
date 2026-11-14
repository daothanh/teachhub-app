/// Khóa `GetIt` của host mà mini-app được phép đọc (spec §3.5).
abstract final class TeachHubDiKey {
  /// `Dio` gọi toàn bộ TeachHub API (`<base>/v1`), đã gắn đủ chuỗi
  /// interceptor của host: header chuẩn, Bearer + refresh, retry, log.
  static const api = 'teachhubApi';

  /// `Dio` không baseURL và không Bearer, cho URL presigned R2.
  static const objectStorage = 'objectStorage';
}
