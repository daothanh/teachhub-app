import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'invite_models.dart';

/// Lời mời phụ huynh (US-1.6). Lỗi ra ngoài là [ApiException]. Hai lệnh ghi
/// đều bắt buộc `Idempotency-Key`: cùng khóa = cùng một lệnh.
abstract class InviteRepository {
  /// `POST /students/{id}/invites`: link + mã ngắn mới; lời mời còn hạn cũ của
  /// phụ huynh đó bị vô hiệu.
  Future<InviteLink> create(
    String studentId,
    String guardianId, {
    required String idempotencyKey,
  });

  /// `POST /invites/{id}/resend`: cấp lại cho lời mời hết hạn hoặc đã thu hồi.
  Future<InviteLink> resend(String inviteId, {required String idempotencyKey});
}

InviteRepository inviteRepository() => GetIt.I<InviteRepository>();

class DioInviteRepository implements InviteRepository {
  DioInviteRepository(this._dio);
  final Dio _dio;

  @override
  Future<InviteLink> create(
    String studentId,
    String guardianId, {
    required String idempotencyKey,
  }) => _post('/students/$studentId/invites', {
    'guardianId': guardianId,
  }, idempotencyKey);

  @override
  Future<InviteLink> resend(
    String inviteId, {
    required String idempotencyKey,
  }) => _post('/invites/$inviteId/resend', null, idempotencyKey);

  Future<InviteLink> _post(String path, Object? body, String key) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(headers: {'Idempotency-Key': key}),
      );
      return InviteLink.fromJson(r.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    } catch (_) {
      throw const ApiException.unexpected();
    }
  }
}
