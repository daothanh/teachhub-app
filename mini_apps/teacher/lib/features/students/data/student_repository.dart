import 'package:dio/dio.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'student_models.dart';

/// 409 `STUDENT_POSSIBLE_DUPLICATE`: trùng họ tên và ngày sinh với hồ sơ có sẵn.
class StudentDuplicateException implements Exception {
  const StudentDuplicateException(this.candidates);
  final List<StudentCandidate> candidates;
}

abstract class StudentRepository {
  /// Lỗi API ném [ApiException]; trùng hồ sơ ném [StudentDuplicateException].
  Future<Student> create(StudentDraft draft, {bool confirmNew = false});
}

class DioStudentRepository implements StudentRepository {
  DioStudentRepository(this._api);
  final Dio _api;

  @override
  Future<Student> create(StudentDraft draft, {bool confirmNew = false}) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/students',
        data: draft.toJson(confirmNew: confirmNew),
      );
      return Student.fromJson(res.data!);
    } on DioException catch (e) {
      final res = e.response;
      final err = res == null
          ? const ApiException.network()
          : ApiException.fromResponse(
              res.statusCode,
              res.data,
              retryAfterHeader: res.headers.value('retry-after'),
            );
      if (err.code == ApiErrorCode.studentPossibleDuplicate) {
        final raw = err.details['candidates'] as List? ?? const [];
        throw StudentDuplicateException([
          for (final c in raw)
            StudentCandidate.fromJson((c as Map).cast<String, dynamic>()),
        ]);
      }
      throw err;
    }
  }
}
