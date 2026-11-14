import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/data/local_db/teacher_database.dart';
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
    await c.dispose();
    expect(
      GetIt.I.isRegistered<TeacherDatabase>(
        instanceName: TeacherController.databaseKey,
      ),
      isFalse,
    );
  });
}
