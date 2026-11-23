import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
import 'package:teacher/features/students/data/contacts_service.dart';
import 'package:teacher/teacher.dart';

void main() {
  test('init registers the database lazily; dispose removes it', () async {
    final c = TeacherController.instance;
    await c.init();
    await c.init(); // gọi lại không lỗi
    expect(
      GetIt.I.isRegistered<TeacherDatabase>(
        instanceName: TeacherController.databaseKey,
      ),
      isTrue,
    );
    // Nút danh bạ ở bước 2 onboarding cần dịch vụ này (lỗi bắt được trên máy thật).
    expect(GetIt.I.isRegistered<ContactsService>(), isTrue);
    await c.dispose();
    expect(
      GetIt.I.isRegistered<TeacherDatabase>(
        instanceName: TeacherController.databaseKey,
      ),
      isFalse,
    );
  });
}
