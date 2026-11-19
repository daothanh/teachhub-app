import 'package:go_router/go_router.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'data/class_models.dart';
import 'pages/class_detail_page.dart';
import 'pages/class_form_page.dart';
import 'pages/classes_list_page.dart';
import 'pages/student_picker_page.dart';

/// Đường dẫn các màn lớp học (T06, T06a, T06b, chọn học viên).
abstract final class ClassesRoutes {
  static const list = '${TeachHubRoutes.teacher}/classes';
  static const create = '$list/new';
  static String detail(String id) => '$list/$id';
  static String edit(String id) => '$list/$id/edit';
  static String addStudent(String id) => '$list/$id/add-student';
}

/// `/new` đứng trước `/:id` để không bị nuốt thành id.
List<RouteBase> classesRoutes(String moduleId) => [
  GoRoute(
    path: ClassesRoutes.list,
    name: '$moduleId.classes',
    builder: (context, state) => const ClassesListPage(),
  ),
  GoRoute(
    path: ClassesRoutes.create,
    name: '$moduleId.classes.new',
    builder: (context, state) => const ClassFormPage(),
  ),
  GoRoute(
    path: '${ClassesRoutes.list}/:id',
    name: '$moduleId.classes.detail',
    builder: (context, state) =>
        ClassDetailPage(classId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '${ClassesRoutes.list}/:id/edit',
    name: '$moduleId.classes.edit',
    builder: (context, state) => ClassFormPage(
      classId: state.pathParameters['id'],
      initial: state.extra as TeachClass?,
    ),
  ),
  GoRoute(
    path: '${ClassesRoutes.list}/:id/add-student',
    name: '$moduleId.classes.addStudent',
    builder: (context, state) =>
        StudentPickerPage(classId: state.pathParameters['id']!),
  ),
];
