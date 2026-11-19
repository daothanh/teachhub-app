import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'pages/student_form_page.dart';

/// Đường dẫn T07 (thêm, sửa học viên).
abstract final class StudentsRoutes {
  static const create = '${TeachHubRoutes.teacher}/students/new';

  /// [classId] và [status] để tải hồ sơ đầy đủ (hợp đồng chưa có
  /// `GET /students/{id}`): học viên đang ghi danh ở lớp đó.
  static String edit(
    String id, {
    required String classId,
    String status = 'active',
  }) =>
      '${TeachHubRoutes.teacher}/students/$id/edit'
      '?classId=$classId&status=$status';
}

/// Route sửa học viên (route thêm mới nằm dưới `/t` trong [TeacherController]).
List<RouteBase> studentsRoutes(String moduleId) => [
  GoRoute(
    path: '${TeachHubRoutes.teacher}/students/:id/edit',
    name: '$moduleId.studentEdit',
    builder: (context, state) => StudentEditPage(
      studentId: state.pathParameters['id']!,
      classId: state.uri.queryParameters['classId'] ?? '',
      status: state.uri.queryParameters['status'] ?? 'active',
    ),
  ),
];
