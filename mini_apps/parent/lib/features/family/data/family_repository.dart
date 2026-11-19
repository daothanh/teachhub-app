import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'family_models.dart';

/// API `/family/**` của phụ huynh (US-0.3 AC4, US-0.4). Lỗi ra ngoài là
/// [ApiException]; chưa đồng ý điều khoản thì host đã chuyển về màn đồng ý.
abstract interface class FamilyRepository {
  Future<List<FamilyStudent>> students();

  /// [week]: một ngày bất kỳ trong tuần cần xem; bỏ trống = tuần hiện tại.
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week});
}

class DioFamilyRepository implements FamilyRepository {
  DioFamilyRepository(this._dio);
  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e) ?? e;
    }
  }

  @override
  Future<List<FamilyStudent>> students() => _guard(() async {
    final res = await _dio.get<Map<String, dynamic>>('/family/students');
    final items = res.data?['items'];
    if (items is! List) throw const ApiException.unexpected();
    return [
      for (final i in items) FamilyStudent.fromJson(i as Map<String, dynamic>),
    ];
  });

  @override
  Future<AttendanceWeek> attendance(String studentId, {DateTime? week}) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/family/students/${Uri.encodeComponent(studentId)}/attendance',
          queryParameters: {
            if (week != null)
              'week':
                  '${week.year.toString().padLeft(4, '0')}-'
                  '${week.month.toString().padLeft(2, '0')}-'
                  '${week.day.toString().padLeft(2, '0')}',
          },
        );
        final data = res.data;
        if (data == null) throw const ApiException.unexpected();
        return AttendanceWeek.fromJson(data);
      });
}
