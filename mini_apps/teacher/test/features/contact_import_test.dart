import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:teacher/features/students/cubit/contact_import_cubit.dart';
import 'package:teacher/features/students/data/contacts_service.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';
import 'package:teacher/features/students/pages/contact_import_page.dart';
import 'package:teacher/features/students/pages/student_form_page.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

const _a = PickableContact(id: 'a', name: 'Minh Anh', phone: '+84 912 345 678');
const _b = PickableContact(id: 'b', name: 'Bảo Ngọc', phone: '0987.654.321');
const _c = PickableContact(id: 'c', name: 'Gia Hân', phone: '84901234567');
const _contacts = [_a, _b, _c];

const _candidate = StudentCandidate(id: 's-old', fullName: 'Minh Anh Bin');

void main() {
  tearDown(GetIt.I.reset);

  test('normalizePhone: +84/84 → 0, bỏ ký tự thừa, số quốc tế giữ +', () {
    expect(normalizePhone('+84 912-345-678'), '0912345678');
    expect(normalizePhone('84901234567'), '0901234567');
    expect(normalizePhone('(091) 234.5678'), '0912345678');
    expect(normalizePhone('+1 415 555 0100'), '+14155550100');
    expect(normalizePhone('  '), isNull);
    expect(normalizePhone(null), isNull);
  });

  group('cubit', () {
    test(
      'quyền bị từ chối: không nạp danh bạ; vĩnh viễn thì mở Cài đặt',
      () async {
        final svc = FakeContactsService(
          access: ContactsAccess.denied,
          contacts: _contacts,
        );
        final cubit = ContactImportCubit(svc, FakeStudentRepository([]));
        expect(svc.requests, 0); // dựng cubit chưa hỏi quyền
        await cubit.start();
        expect(cubit.state.phase, ImportPhase.denied);
        expect(cubit.state.contacts, isEmpty);

        svc.access = ContactsAccess.permanentlyDenied;
        await cubit.start();
        expect(cubit.state.phase, ImportPhase.permanentlyDenied);
        await cubit.openSettings();
        expect(svc.settingsOpened, 1);
      },
    );

    test(
      'chọn 3, sửa 1, bỏ 1, lưu: trùng + lỗi mạng rồi thử lại cùng khóa',
      () async {
        final repo = FakeStudentRepository([
          StudentDuplicateException(const [_candidate]), // dòng a (đã sửa tên)
          const ApiException.network(), // dòng c
          const Student(id: 's-c', fullName: 'Gia Hân'), // c thử lại
        ]);
        final cubit = ContactImportCubit(
          FakeContactsService(contacts: _contacts),
          repo,
        );
        await cubit.start();
        for (final id in ['a', 'b', 'c']) {
          cubit.toggle(id);
        }
        cubit.confirmSelection();
        expect(cubit.state.rows.map((r) => r.phone), [
          '0912345678',
          '0987654321',
          '0901234567',
        ]);
        cubit.edit('a', name: 'Minh Anh Bin');
        cubit.remove('b');
        expect(cubit.state.rows.map((r) => r.id), ['a', 'c']);

        await cubit.saveAll();
        expect(repo.calls.map((c) => c.draft.fullName), [
          'Minh Anh Bin',
          'Gia Hân',
        ]);
        // SĐT thành SĐT phụ huynh 1.
        expect(repo.calls[0].draft.guardians.single.phone, '0912345678');
        final rows = {for (final r in cubit.state.rows) r.id: r};
        expect(rows['a']!.status, RowStatus.duplicate);
        expect(rows['a']!.candidates, [_candidate]);
        expect(rows['c']!.status, RowStatus.failed);

        // Thử lại: chỉ dòng c, cùng khóa.
        await cubit.saveAll();
        expect(repo.calls, hasLength(3));
        expect(repo.calls[2].draft.fullName, 'Gia Hân');
        expect(repo.calls[2].key, repo.calls[1].key);
        expect(cubit.state.rows.last.status, RowStatus.saved);
        expect(cubit.state.rows.first.status, RowStatus.duplicate);
      },
    );

    test('đổi nội dung dòng thì khóa đổi; confirmNew gửi lại kèm cờ', () async {
      final repo = FakeStudentRepository([
        StudentDuplicateException(const [_candidate]),
        const ApiException.network(),
        StudentDuplicateException(const [_candidate]),
        const Student(id: 's-new', fullName: 'x'),
      ]);
      final cubit = ContactImportCubit(
        FakeContactsService(contacts: _contacts),
        repo,
      );
      await cubit.start();
      cubit.toggle('a');
      cubit.confirmSelection();
      await cubit.saveAll();
      expect(cubit.state.rows.single.status, RowStatus.duplicate);
      await cubit.confirmNew('a'); // lỗi mạng, cùng nội dung + confirmNew
      expect(repo.calls[1].confirmNew, isTrue);
      expect(repo.calls[1].key, isNot(repo.calls[0].key));

      cubit.edit('a', phone: '0911111111');
      await cubit.saveAll();
      expect(repo.calls[2].key, isNot(repo.calls[1].key));
      await cubit.confirmNew('a');
      expect(cubit.state.rows.single.savedId, 's-new');
    });

    test('dòng sai SĐT không được gửi', () async {
      final repo = FakeStudentRepository([]);
      final cubit = ContactImportCubit(
        FakeContactsService(contacts: _contacts),
        repo,
      );
      await cubit.start();
      cubit.toggle('a');
      cubit.confirmSelection();
      cubit.edit('a', phone: '12ab');
      expect(cubit.state.canSave, isFalse);
      await cubit.saveAll();
      expect(repo.calls, isEmpty);
    });
  });

  group('widget', () {
    Future<(FakeContactsService, FakeStudentRepository)> open(
      WidgetTester tester, {
      ContactsAccess access = ContactsAccess.granted,
      List<Object> results = const [],
      double textScale = 1,
    }) async {
      final svc = FakeContactsService(access: access, contacts: _contacts);
      final repo = FakeStudentRepository([...results]);
      GetIt.I
        ..registerSingleton<ContactsService>(svc)
        ..registerSingleton<StudentRepository>(repo);
      await pumpApp(tester, const ContactImportPage(), textScale: textScale);
      return (svc, repo);
    }

    testWidgets('bị từ chối vĩnh viễn: giải thích, Mở Cài đặt, nhập tay', (
      tester,
    ) async {
      final (svc, _) = await open(
        tester,
        access: ContactsAccess.permanentlyDenied,
      );
      expect(find.text('Chưa có quyền đọc danh bạ'), findsOneWidget);
      expect(find.text('Cho phép lại'), findsNothing);
      await tester.tap(find.text('Mở Cài đặt'));
      await tester.pump();
      expect(svc.settingsOpened, 1);
      expect(find.text('Nhập tay'), findsOneWidget);
    });

    testWidgets('từ chối thường: có thêm nút Cho phép lại', (tester) async {
      await open(tester, access: ContactsAccess.denied);
      expect(find.text('Cho phép lại'), findsOneWidget);
    });

    testWidgets(
      'chọn 3, sửa 1, bỏ 1, lưu (trùng + lỗi mạng), thử lại; textScale 1.3',
      (tester) async {
        final (_, repo) = await open(
          tester,
          textScale: 1.3,
          results: [
            StudentDuplicateException(const [_candidate]),
            const ApiException.network(),
            const Student(id: 's-c', fullName: 'Gia Hân'),
          ],
        );
        for (final n in ['Minh Anh', 'Bảo Ngọc', 'Gia Hân']) {
          await tester.tap(find.text(n));
        }
        await tester.pump();
        await tester.tap(find.text('Tiếp tục (3)'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Bỏ Bảo Ngọc, sửa tên Minh Anh.
        await tester.tap(find.byTooltip('Bỏ Bảo Ngọc'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText).first, 'Minh Anh Bin');
        await tester.pump();

        await tester.tap(find.text('Lưu 2 học viên'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(repo.calls, hasLength(2));
        expect(find.text('Có thể trùng hồ sơ'), findsOneWidget);
        expect(
          find.text('Chưa lưu được. Không có mạng. Thử lại sau.'),
          findsOneWidget,
        );

        await tester.tap(find.text('Lưu 1 học viên'));
        await tester.pumpAndSettle();
        expect(repo.calls, hasLength(3));
        expect(repo.calls[2].key, repo.calls[1].key);
        expect(find.text('Đã lưu'), findsOneWidget);

        // Hộp thoại trùng của đúng dòng đó.
        await tester.tap(find.text('Xem hồ sơ trùng'));
        await tester.pumpAndSettle();
        expect(find.text('Có phải cùng một em?'), findsOneWidget);
        expect(find.text('Minh Anh Bin'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('form T07 có nút Thêm từ danh bạ, chỉ hỏi quyền khi bấm', (
      tester,
    ) async {
      final svc = FakeContactsService(
        access: ContactsAccess.denied,
        contacts: _contacts,
      );
      GetIt.I
        ..registerSingleton<ContactsService>(svc)
        ..registerSingleton<StudentRepository>(FakeStudentRepository([]));
      await pumpApp(tester, Scaffold(body: StudentFormScope(onSaved: (_) {})));
      expect(svc.requests, 0);
      await tester.tap(find.text('Thêm từ danh bạ'));
      await tester.pumpAndSettle();
      expect(svc.requests, 1);
      expect(find.text('Chưa có quyền đọc danh bạ'), findsOneWidget);
    });
  });
}
