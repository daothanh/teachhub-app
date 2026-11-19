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

  /// Các lệnh ghi nhận [idempotencyKey]: cùng khóa = cùng một lệnh (gửi lại
  /// sau lỗi mạng không tạo bản trùng). `null` thì host tự sinh cho POST/PATCH.
  Future<ClassCreated> create(ClassInput input, {String? idempotencyKey});
  Future<TeachClass> update(
    String id,
    ClassInput input, {
    String? idempotencyKey,
  });
  Future<TeachClass> archive(String id, {String? idempotencyKey});
  Future<List<RosterEntry>> roster(String id);
  Future<EnrollResult> enroll(
    String classId,
    String studentId, {
    String? idempotencyKey,
  });

  /// Tìm không dấu theo họ tên; `q` tối thiểu 2 ký tự.
  Future<Paginated<StudentSummary>> searchStudents(String q);
  Future<ScheduleRulesResult> putRules(
    String classId,
    List<ScheduleRule> rules, {
    String? idempotencyKey,
  });

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
  Future<ClassCreated> create(ClassInput input, {String? idempotencyKey}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/classes',
          data: input.toJson(),
          options: _key(idempotencyKey),
        );
        return ClassCreated.fromJson(r.data!);
      });

  @override
  Future<TeachClass> update(
    String id,
    ClassInput input, {
    String? idempotencyKey,
  }) => _call(() async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/classes/$id',
      data: input.toJson(),
      options: _key(idempotencyKey),
    );
    return TeachClass.fromJson(r.data!);
  });

  @override
  Future<TeachClass> archive(String id, {String? idempotencyKey}) =>
      _call(() async {
        final r = await _dio.post<Map<String, dynamic>>(
          '/classes/$id/archive',
          options: _key(idempotencyKey),
        );
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
  Future<EnrollResult> enroll(
    String classId,
    String studentId, {
    String? idempotencyKey,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/classes/$classId/enrollments',
      data: {'studentId': studentId},
      options: _key(idempotencyKey),
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
    List<ScheduleRule> rules, {
    String? idempotencyKey,
  }) => _call(() async {
    // Interceptor của host chỉ tự gắn khóa cho POST/PATCH; PUT này hợp đồng
    // cũng bắt buộc khóa nên cubit luôn truyền vào.
    final r = await _dio.put<Map<String, dynamic>>(
      '/classes/$classId/schedule-rules',
      data: {
        'rules': [for (final x in rules) x.toJson()],
      },
      options: _key(idempotencyKey),
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

Options? _key(String? key) =>
    key == null ? null : Options(headers: {'Idempotency-Key': key});

/// Mọi lỗi ra ngoài là [ApiException]: lỗi Dio theo spec §5.6; lỗi đọc phản hồi
/// (data null, sai kiểu, thiếu trường, `status` lạ) thành lỗi máy chủ chung để
/// Cubit không kẹt ở trạng thái đang tải.
Future<T> _call<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on Object catch (e) {
    // Lỗi đọc thân phản hồi (Dio gói TypeError/FormatException vào `error`)
    // không phải lỗi mạng dù không có response.
    final parseFailure =
        e is TypeError ||
        e is FormatException ||
        (e is DioException &&
            (e.error is TypeError || e.error is FormatException));
    throw (parseFailure ? null : ApiException.fromDio(e)) ??
        const ApiException(
          code: ApiErrorCode.internalError,
          wireCode: null,
          status: 500,
        );
  }
}
