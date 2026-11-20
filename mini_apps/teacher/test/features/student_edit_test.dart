import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teacher/features/students/pages/student_form_page.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

const _existing = Student(
  id: 's1',
  fullName: 'Minh Anh',
  guardians: [
    GuardianDraft(
      id: 'g1',
      fullName: 'Lan',
      phone: '0912345678',
      relation: GuardianRelation.mother,
    ),
  ],
);

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('sửa hồ sơ: điền sẵn, PATCH giữ id và quan hệ phụ huynh', (
    tester,
  ) async {
    final repo = FakeStudentRepository([_existing]);
    GetIt.I.registerSingleton<StudentRepository>(repo);
    final saved = <String>[];
    await pumpApp(
      tester,
      Scaffold(
        body: StudentFormScope(onSaved: saved.add, initial: _existing),
      ),
      textScale: 2,
    );
    expect(find.text('Minh Anh'), findsOneWidget);
    expect(find.text('0912345678'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Lưu học viên'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Lưu học viên'));
    await tester.pumpAndSettle();

    expect(repo.calls, isEmpty);
    final u = repo.updates.single;
    expect(u.id, 's1');
    final g = u.draft.toPatchJson()['guardians'] as List;
    expect((g.single as Map)['id'], 'g1');
    expect((g.single as Map)['relation'], 'mother');
    expect(saved, ['s1']);
    expect(tester.takeException(), isNull);
  });
}
