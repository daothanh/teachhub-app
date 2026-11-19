import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'student_models.dart';

/// 409 `STUDENT_POSSIBLE_DUPLICATE`: trùng họ tên và ngày sinh với hồ sơ có sẵn.
class StudentDuplicateException implements Exception {
  const StudentDuplicateException(this.candidates);
  final List<StudentCandidate> candidates;
}

abstract class StudentRepository {
  /// [idempotencyKey]: giữ nguyên khi thử lại cùng nội dung (do cubit quản).
  /// Lỗi API ném [ApiException]; trùng hồ sơ ném [StudentDuplicateException].
  Future<Student> create(
    StudentDraft draft, {
    required String idempotencyKey,
    bool confirmNew = false,
  });
}

class DioStudentRepository implements StudentRepository {
  DioStudentRepository(this._api);
  final Dio _api;

  @override
  Future<Student> create(
    StudentDraft draft, {
    required String idempotencyKey,
    bool confirmNew = false,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/students',
        data: draft.toJson(confirmNew: confirmNew),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return Student.fromJson(res.data!);
    } on DioException catch (e) {
      final err = ApiException.fromDio(e)!;
      if (err.code == ApiErrorCode.studentPossibleDuplicate) {
        throw StudentDuplicateException(_candidates(err));
      }
      throw err;
    } catch (_) {
      throw const ApiException.unexpected();
    }
  }

  List<StudentCandidate> _candidates(ApiException err) {
    try {
      return [
        for (final c in err.details['candidates'] as List? ?? const [])
          StudentCandidate.fromJson((c as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      throw const ApiException.unexpected();
    }
  }
}
