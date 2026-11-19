import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teacher/features/students/pages/student_form_page.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

const _saved = Student(id: 's-new', fullName: 'Minh Anh');
const _candidate = StudentCandidate(
  id: 's-old',
  fullName: 'Minh Anh',
  dob: '2011-05-20',
  school: 'THCS Lê Lợi',
);

ApiException _api(int status, String code, {Map<String, Object?>? details}) =>
    ApiException.fromResponse(status, {
      'code': code,
      'message': 'x',
      'details': ?details,
    });

Future<FakeStudentRepository> _open(
  WidgetTester tester,
  List<Object> results,
  List<String> saved, {
  double textScale = 1,
}) async {
  final repo = FakeStudentRepository(results);
  GetIt.I.registerSingleton<StudentRepository>(repo);
  await pumpApp(
    tester,
    Scaffold(body: StudentFormScope(onSaved: saved.add)),
    textScale: textScale,
  );
  return repo;
}

Future<void> _fillName(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, 'Minh Anh');
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Lưu học viên'));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('đường chính: chỉ họ tên là đủ, gửi POST rồi báo đã lưu', (
    tester,
  ) async {
    final saved = <String>[];
    final repo = await _open(tester, [_saved], saved);
    await _fillName(tester);
    await _save(tester);

    expect(repo.calls.single.draft, const StudentDraft(fullName: 'Minh Anh'));
    expect(repo.calls.single.confirmNew, isFalse);
    expect(saved, ['s-new']);
  });

  testWidgets('thiếu họ tên: báo lỗi tại ô, không gọi API', (tester) async {
    final repo = await _open(tester, [], []);
    await _save(tester);

    expect(find.text('Nhập họ tên học viên.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('phụ huynh: tối đa 2, SĐT sai bị chặn, SĐT hợp lệ được gửi', (
    tester,
  ) async {
    final repo = await _open(tester, [_saved], []);
    await _fillName(tester);
    await tester.tap(find.text('Thêm phụ huynh'));
    await tester.pump();
    await tester.tap(find.text('Thêm phụ huynh'));
    await tester.pump();
    expect(find.text('Thêm phụ huynh'), findsNothing); // đã đủ 2

    final fields = find.byType(EditableText);
    // 0 tên, 1 ngày sinh, 2 trường, 3 ghi chú, 4-5 PH1, 6-7 PH2.
    await tester.enterText(fields.at(4), 'Hải');
    await tester.enterText(fields.at(5), '12ab');
    await tester.enterText(fields.at(6), 'Lan');
    await _save(tester);
    expect(find.text('Số điện thoại chưa đúng.'), findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.enterText(fields.at(5), '0912345678');
    await _save(tester);
    expect(repo.calls.single.draft.guardians, const [
      GuardianDraft(fullName: 'Hải', phone: '0912345678'),
      GuardianDraft(fullName: 'Lan'),
    ]);
  });

  testWidgets('409 trùng: chọn "Không, thêm em mới" gửi lại kèm confirmNew', (
    tester,
  ) async {
    final saved = <String>[];
    final repo = await _open(tester, [
      const StudentDuplicateException([_candidate]),
      _saved,
    ], saved);
    await _fillName(tester);
    await _save(tester);

    expect(find.text('Có phải cùng một em?'), findsOneWidget);
    expect(find.textContaining('THCS Lê Lợi'), findsOneWidget);

    await tester.tap(find.text('Không, thêm em mới'));
    await tester.pumpAndSettle();

    expect(repo.calls.map((c) => c.confirmNew), [false, true]);
    expect(repo.calls.last.draft, repo.calls.first.draft);
    expect(saved, ['s-new']);
  });

  testWidgets('409 trùng: "Đúng, là em này" dùng hồ sơ có sẵn, không tạo mới', (
    tester,
  ) async {
    final saved = <String>[];
    final repo = await _open(tester, [
      const StudentDuplicateException([_candidate]),
    ], saved);
    await _fillName(tester);
    await _save(tester);
    await tester.tap(find.text('Đúng, là em này'));
    await tester.pumpAndSettle();

    expect(saved, ['s-old']);
    expect(repo.calls, hasLength(1));
  });

  testWidgets('409 trùng: "Quay lại sửa" đóng hộp thoại, không gửi lại', (
    tester,
  ) async {
    final saved = <String>[];
    final repo = await _open(tester, [
      const StudentDuplicateException([_candidate]),
    ], saved);
    await _fillName(tester);
    await _save(tester);
    await tester.tap(find.text('Quay lại sửa'));
    await tester.pumpAndSettle();

    expect(find.text('Có phải cùng một em?'), findsNothing);
    expect(saved, isEmpty);
    expect(repo.calls, hasLength(1));
  });

  for (final (status, code, message) in [
    (
      402,
      'PLAN_LIMIT_EXCEEDED',
      'Gói hiện tại đã đủ số học viên. Nâng cấp để thêm.',
    ),
    (
      409,
      'IDEMPOTENCY_IN_PROGRESS',
      'Yêu cầu đang xử lý. Thử lại sau giây lát.',
    ),
    (422, 'VALIDATION_FAILED', 'Thông tin chưa hợp lệ. Kiểm tra lại các ô.'),
  ]) {
    testWidgets('$status $code: hiện thông báo, form giữ nguyên', (
      tester,
    ) async {
      final saved = <String>[];
      await _open(tester, [_api(status, code)], saved);
      await _fillName(tester);
      await _save(tester);

      expect(find.text(message), findsOneWidget);
      expect(find.text('Minh Anh'), findsOneWidget);
      expect(saved, isEmpty);
    });
  }

  testWidgets('mất mạng: thông báo không có mạng', (tester) async {
    await _open(tester, [const ApiException.network()], []);
    await _fillName(tester);
    await _save(tester);
    expect(find.text('Không có mạng. Thử lại sau.'), findsOneWidget);
  });

  testWidgets(
    'Idempotency-Key: thử lại sau lỗi giữ khóa, đổi nội dung thì khóa mới',
    (tester) async {
      final repo = await _open(tester, [
        const ApiException.network(),
        const ApiException.network(),
        const ApiException.network(),
      ], []);
      await _fillName(tester);
      await _save(tester);
      await _save(tester);
      expect(repo.calls[1].key, repo.calls[0].key);

      await tester.enterText(find.byType(EditableText).first, 'Minh Anh B');
      await _save(tester);
      expect(repo.calls[2].key, isNot(repo.calls[0].key));
    },
  );

  testWidgets('confirmNew dùng khóa mới', (tester) async {
    final repo = await _open(tester, [
      const StudentDuplicateException([_candidate]),
      _saved,
    ], []);
    await _fillName(tester);
    await _save(tester);
    await tester.tap(find.text('Không, thêm em mới'));
    await tester.pumpAndSettle();
    expect(repo.calls[1].key, isNot(repo.calls[0].key));
  });

  testWidgets('lưu xong thì khóa form, không gửi lần hai', (tester) async {
    final repo = await _open(tester, [_saved], []);
    await _fillName(tester);
    await _save(tester);
    await tester.tap(find.text('Lưu học viên'));
    await tester.pumpAndSettle();
    expect(repo.calls, hasLength(1));
    expect(
      tester.widget<EditableText>(find.byType(EditableText).first).readOnly,
      isTrue,
    );
  });

  testWidgets('nút xóa phụ huynh có số thứ tự', (tester) async {
    await _open(tester, [], []);
    await tester.tap(find.text('Thêm phụ huynh'));
    await tester.pump();
    expect(find.text('Xóa phụ huynh 1'), findsOneWidget);
  });

  testWidgets('chữ phóng 1.3 và 2 phụ huynh: không overflow', (tester) async {
    await _open(tester, [], [], textScale: 1.3);
    await tester.tap(find.text('Thêm phụ huynh'));
    await tester.pump();
    await tester.tap(find.text('Thêm phụ huynh'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('hộp thoại trùng ở chữ phóng 1.3 không overflow', (tester) async {
    await _open(
      tester,
      [
        const StudentDuplicateException([_candidate, _candidate]),
      ],
      [],
      textScale: 1.3,
    );
    await _fillName(tester);
    await _save(tester);
    expect(find.text('Có phải cùng một em?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
