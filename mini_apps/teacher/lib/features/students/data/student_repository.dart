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

  /// `PATCH /students/{id}`: sửa hồ sơ và thay cả danh sách phụ huynh (≤ 2).
  Future<Student> update(
    String id,
    StudentDraft draft, {
    required String idempotencyKey,
  });

  /// Hồ sơ đầy đủ (kèm phụ huynh, SĐT) của một học viên đang ghi danh ở lớp.
  /// Hợp đồng chưa có `GET /students/{id}` nên duyệt `GET /students?classId`
  /// theo trang; không thấy thì ném [ApiException] 404.
  Future<Student> find(
    String id, {
    required String classId,
    String status = 'active',
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

  @override
  Future<Student> update(
    String id,
    StudentDraft draft, {
    required String idempotencyKey,
  }) async {
    try {
      final res = await _api.patch<Map<String, dynamic>>(
        '/students/$id',
        data: draft.toPatchJson(),
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      return Student.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    } catch (_) {
      throw const ApiException.unexpected();
    }
  }

  @override
  Future<Student> find(
    String id, {
    required String classId,
    String status = 'active',
  }) async {
    try {
      for (var page = 1; ; page++) {
        final res = await _api.get<Map<String, dynamic>>(
          '/students',
          queryParameters: {
            'classId': classId,
            'status': status,
            'page': page,
            'pageSize': 100,
          },
        );
        final data = Paginated.fromJson(res.data!, Student.fromJson);
        for (final s in data.items) {
          if (s.id == id) return s;
        }
        if (!data.hasMore || data.items.isEmpty) break;
      }
      throw const ApiException(
        code: ApiErrorCode.notFound,
        wireCode: 'NOT_FOUND',
        status: 404,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e)!;
    } on ApiException {
      rethrow;
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
