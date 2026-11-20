import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

/// `POST /invites/preview`: chỉ tên giáo viên và tên gọi của con.
class InvitePreview {
  const InvitePreview({
    required this.teacherName,
    required this.studentGivenName,
    required this.expiresAt,
  });

  final String teacherName;
  final String studentGivenName;
  final DateTime expiresAt;
}

/// `POST /invites/accept` và `/invites/redeem-code`.
class InviteAccepted {
  const InviteAccepted({
    required this.membershipId,
    required this.studentId,
    required this.studentName,
  });

  final String membershipId;
  final String studentId;
  final String studentName;
}

/// API lời mời. Token và mã ở body (không ở đường dẫn) nên không vào log URL.
/// Lỗi ra ngoài là [ApiException]: 410 `INVITE_INVALID`, 429
/// `INVITE_CODE_LOCKED`, 403 `CONSENT_REQUIRED`.
abstract interface class InviteRepository {
  Future<InvitePreview> preview(String token);
  Future<InviteAccepted> accept(String token);
  Future<InviteAccepted> redeemCode(String code);
}

class DioInviteRepository implements InviteRepository {
  DioInviteRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, String> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return res.data ?? (throw const ApiException.unexpected());
    } on DioException catch (e) {
      throw ApiException.fromDio(e) ?? e;
    }
  }

  @override
  Future<InvitePreview> preview(String token) async {
    final j = await _post('/invites/preview', {'token': token});
    return InvitePreview(
      teacherName: j['teacherName'] as String,
      studentGivenName: j['studentGivenName'] as String,
      expiresAt: DateTime.parse(j['expiresAt'] as String),
    );
  }

  InviteAccepted _accepted(Map<String, dynamic> j) => InviteAccepted(
    membershipId: j['membershipId'] as String,
    studentId: j['studentId'] as String,
    studentName: j['studentName'] as String,
  );

  @override
  Future<InviteAccepted> accept(String token) async =>
      _accepted(await _post('/invites/accept', {'token': token}));

  @override
  Future<InviteAccepted> redeemCode(String code) async =>
      _accepted(await _post('/invites/redeem-code', {'code': code}));
}
