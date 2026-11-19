import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'class_models.dart';

/// API lớp học, buổi học và ghi danh (spec §5, US-1.1, US-2.1, US-1.4 AC3).
/// Mọi lỗi ra ngoài là [ApiException]; test thay bằng bản giả của lớp này.
abstract class ClassesRepository {
  Future<Paginated<TeachClass>> list({
    ClassStatus status = ClassStatus.active,
    int page = 1,
  });
  Future<TeachClass> get(String id);
  Future<ClassCreated> create(ClassInput input);
  Future<TeachClass> update(String id, ClassInput input);
  Future<TeachClass> archive(String id);
  Future<List<RosterEntry>> roster(String id);
  Future<EnrollResult> enroll(String classId, String studentId);

  /// Tìm không dấu theo họ tên; `q` tối thiểu 2 ký tự.
  Future<Paginated<StudentSummary>> searchStudents(String q);
  Future<ScheduleRulesResult> putRules(
    String classId,
    List<ScheduleRule> rules,
  );

  /// Tối đa 62 ngày (`from`, `to` gồm cả hai đầu), không phân trang.
  Future<List<ClassSession>> sessions({
    required String from,
    required String to,
    String? classId,
  });
}

/// Bản dùng thật: `Dio` của host (`TeachHubDiKey.api`) đã có Bearer và
/// `Idempotency-Key` cho POST/PATCH.
ClassesRepository classesRepository() =>
    GetIt.I.isRegistered<ClassesRepository>()
    ? GetIt.I<ClassesRepository>()
    : DioClassesRepository(GetIt.I<Dio>(instanceName: TeachHubDiKey.api));

class DioClassesRepository implements ClassesRepository {
  DioClassesRepository(this._dio);
  final Dio _dio;

  @override
  Future<Paginated<TeachClass>> list({
    ClassStatus status = ClassStatus.active,
    int page = 1,
  }) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/classes',
      queryParameters: {'status': status.name, 'page': page, 'pageSize': 20},
    );
    return Paginated.fromJson(r.data!, TeachClass.fromJson);
  });

  @override
  Future<TeachClass> get(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/classes/$id');
    return TeachClass.fromJson(r.data!);
  });

  @override
  Future<ClassCreated> create(ClassInput input) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/classes',
      data: input.toJson(),
    );
    return ClassCreated.fromJson(r.data!);
  });

  @override
  Future<TeachClass> update(String id, ClassInput input) => _call(() async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/classes/$id',
      data: input.toJson(),
    );
    return TeachClass.fromJson(r.data!);
  });

  @override
  Future<TeachClass> archive(String id) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>('/classes/$id/archive');
    return TeachClass.fromJson(r.data!);
  });

  @override
  Future<List<RosterEntry>> roster(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/classes/$id/roster');
    return [
      for (final e in r.data!['items'] as List)
        RosterEntry.fromJson(e as Map<String, dynamic>),
    ];
  });

  @override
  Future<EnrollResult> enroll(String classId, String studentId) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/classes/$classId/enrollments',
          data: {'studentId': studentId},
        );
        return EnrollResult(
          Enrollment.fromJson(r.data!),
          alreadyEnrolled: r.statusCode == 200,
        );
      });

  @override
  Future<Paginated<StudentSummary>> searchStudents(String q) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/students',
      queryParameters: {'q': q, 'pageSize': 20},
    );
    return Paginated.fromJson(r.data!, StudentSummary.fromJson);
  });

  @override
  Future<ScheduleRulesResult> putRules(
    String classId,
    List<ScheduleRule> rules,
  ) => _call(() async {
    final r = await _dio.put<Map<String, dynamic>>(
      '/classes/$classId/schedule-rules',
      data: {
        'rules': [for (final x in rules) x.toJson()],
      },
    );
    return ScheduleRulesResult.fromJson(r.data!);
  });

  @override
  Future<List<ClassSession>> sessions({
    required String from,
    required String to,
    String? classId,
  }) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>(
      '/sessions',
      queryParameters: {'from': from, 'to': to, 'classId': ?classId},
    );
    return [
      for (final e in r.data!['items'] as List)
        ClassSession.fromJson(e as Map<String, dynamic>),
    ];
  });
}

/// Đổi lỗi Dio thành [ApiException] (spec §5.6); lỗi khác giữ nguyên.
Future<T> _call<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on DioException catch (e) {
    final res = e.response;
    if (res == null) throw const ApiException.network();
    throw ApiException.fromResponse(
      res.statusCode,
      res.data,
      retryAfterHeader: res.headers.value('retry-after'),
    );
  }
}
