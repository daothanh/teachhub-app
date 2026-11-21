import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher/features/billing/billing_routes.dart';
import 'package:teacher/features/billing/data/billing_models.dart';
import 'package:teacher/features/billing/data/billing_repository.dart';
import 'package:teacher/features/billing/pages/invoice_page.dart'
    show InvoicePage;
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/receivables/cubit/receivables_cubit.dart';
import 'package:teacher/features/receivables/data/receivable_models.dart';
import 'package:teacher/features/receivables/data/receivables_repository.dart';
import 'package:teacher/features/receivables/receivables_routes.dart';
import 'package:tasco_ui_kit/tasco_ui_kit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../billing/fake_billing_repository.dart';
import '../classes/fake_classes_repository.dart';
import '../classes/pump.dart';
import 'fake_receivables_repository.dart';

void main() {
  late FakeReceivablesRepository repo;
  late FakeBillingRepository billing;
  late FakeClassesRepository classes;
  setUp(() {
    repo = FakeReceivablesRepository();
    billing = FakeBillingRepository();
    classes = FakeClassesRepository();
    GetIt.I
      ..registerSingleton<ReceivablesRepository>(repo)
      ..registerSingleton<BillingRepository>(billing)
      ..registerSingleton<ClassesRepository>(classes);
  });
  tearDown(GetIt.I.reset);

  Future<GoRouter> open(
    WidgetTester tester,
    String initial, {
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      [
        GoRoute(path: '/', builder: (_, _) => const Scaffold()),
        ...receivablesRoutes('teacher'),
        ...billingRoutes('teacher'),
        ...classesRoutes('teacher'),
      ],
      initial: initial,
      textScale: scale,
    );
    addTearDown(router.dispose);
    return router;
  }

  final rows = [
    sampleRow(id: 'a', name: 'Nguyễn Minh Anh', amount: 700000),
    sampleRow(
      id: 'b',
      name: 'Trần Bảo Bình',
      classes: const ['Toán 9A', 'Lý 9A'],
      amount: 1900000,
      overdue: 75,
      bucket: AgingBucket.over60,
      invoices: 2,
    ),
    sampleRow(
      id: 'c',
      name: 'Lê Chi',
      amount: 300000,
      overdue: 40,
      bucket: AgingBucket.from31To60,
    ),
  ];

  testWidgets('lối vào từ màn kỳ thu mở T11', (tester) async {
    repo.rows = rows;
    await open(tester, BillingRoutes.periods);
    await tester.tap(find.byTooltip('Công nợ'));
    await tester.pumpAndSettle();
    expect(find.text('Tổng còn nợ 2.900.000 đ'), findsOneWidget);
  });

  group('T11 công nợ (AC-1)', () {
    testWidgets(
      'hiện học viên nợ: tên, lớp, số nợ, nhóm tuổi nợ; tổng theo nhóm',
      (tester) async {
        repo.rows = rows;
        await open(tester, ReceivablesRoutes.list);
        expect(find.text('Tổng còn nợ 2.900.000 đ'), findsOneWidget);
        expect(find.text('0–30 ngày · 700.000 đ'), findsOneWidget);
        expect(find.text('31–60 ngày · 300.000 đ'), findsOneWidget);
        expect(find.text('Trên 60 ngày · 1.900.000 đ'), findsOneWidget);
        // Mặc định nợ nhiều trước.
        final names = tester
            .widgetList<Text>(find.textContaining(RegExp('^(Nguyễn|Trần|Lê) ')))
            .map((t) => t.data);
        expect(names.toList(), ['Trần Bảo Bình', 'Nguyễn Minh Anh', 'Lê Chi']);
        expect(find.text('Còn nợ 1.900.000 đ'), findsOneWidget);
        expect(find.text('Toán 9A, Lý 9A · 2 hóa đơn'), findsOneWidget);
        expect(find.text('Trên 60 ngày · Quá hạn 75 ngày'), findsOneWidget);
      },
    );

    testWidgets(
      'lọc theo nhóm: danh sách theo nhóm, tổng các nhóm giữ nguyên',
      (tester) async {
        repo.rows = rows;
        await open(tester, ReceivablesRoutes.list);
        await tester.tap(find.text('Trên 60 ngày · 1.900.000 đ'));
        await tester.pumpAndSettle();
        expect(repo.listArgs.last.bucket, AgingBucket.over60);
        expect(find.text('Trần Bảo Bình'), findsOneWidget);
        expect(find.text('Nguyễn Minh Anh'), findsNothing);
        expect(find.text('0–30 ngày · 700.000 đ'), findsOneWidget);
        await tester.tap(find.text('Tất cả'));
        await tester.pumpAndSettle();
        expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      },
    );

    testWidgets('tìm theo tên (chờ ngừng gõ) và giữ ô tìm kiếm khi tải lại', (
      tester,
    ) async {
      repo.rows = rows;
      await open(tester, ReceivablesRoutes.list);
      await tester.enterText(find.byType(TextField), 'bảo');
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.listArgs, hasLength(1));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(repo.listArgs.last.q, 'bảo');
      expect(find.text('Trần Bảo Bình'), findsOneWidget);
      expect(find.text('Lê Chi'), findsNothing);
      expect(find.text('bảo'), findsOneWidget);
    });

    testWidgets('sắp theo số nợ: đổi chiều', (tester) async {
      repo.rows = rows;
      await open(tester, ReceivablesRoutes.list);
      await tester.tap(find.text('Nợ nhiều trước'));
      await tester.pumpAndSettle();
      expect(repo.listArgs.last.asc, isTrue);
      expect(find.text('Nợ ít trước'), findsOneWidget);
      final names = tester
          .widgetList<Text>(find.textContaining(RegExp('^(Nguyễn|Trần|Lê) ')))
          .map((t) => t.data);
      expect(names.toList(), ['Lê Chi', 'Nguyễn Minh Anh', 'Trần Bảo Bình']);
    });

    testWidgets('cuộn tới cuối tải thêm trang kế', (tester) async {
      repo.rows = [
        for (var i = 0; i < 25; i++)
          sampleRow(
            id: 's$i',
            name: 'Học viên ${i.toString().padLeft(2, '0')}',
            amount: 2000000 - i * 1000,
          ),
      ];
      await open(tester, ReceivablesRoutes.list);
      expect(repo.calls, ['list:1']);
      expect(find.text('Học viên 24'), findsNothing);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(repo.calls, ['list:1', 'list:2']);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(find.text('Học viên 24'), findsOneWidget);
    });

    testWidgets('không ai còn nợ: trạng thái rỗng', (tester) async {
      await open(tester, ReceivablesRoutes.list);
      expect(find.text('Không ai còn nợ'), findsOneWidget);
    });

    testWidgets('lọc theo lớp: chọn lớp trong danh sách, chọn lại tất cả', (
      tester,
    ) async {
      classes.active = [
        sampleClass(id: 'c1', name: 'Toán 9A'),
        sampleClass(id: 'c2', name: 'Lý 9A'),
      ];
      repo.rows = rows;
      repo.studentClass.addAll({'a': 'c1', 'b': 'c2', 'c': 'c2'});
      await open(tester, ReceivablesRoutes.list);
      await tester.tap(find.text('Lớp: Tất cả lớp'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lý 9A'));
      await tester.pumpAndSettle();
      expect(repo.listArgs.last.classId, 'c2');
      expect(find.text('Lớp: Lý 9A'), findsOneWidget);
      expect(find.text('Nguyễn Minh Anh'), findsNothing);
      expect(find.text('Lê Chi'), findsOneWidget);
      await tester.tap(find.text('Lớp: Lý 9A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả lớp').last);
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    });

    testWidgets(
      'không tải được danh sách lớp: ẩn bộ lọc lớp, danh sách vẫn dùng',
      (tester) async {
        classes.listError = const ApiException.network();
        repo.rows = rows;
        await open(tester, ReceivablesRoutes.list);
        expect(find.textContaining('Lớp:'), findsNothing);
        expect(find.text('Trần Bảo Bình'), findsOneWidget);
      },
    );

    testWidgets('làm mới lỗi: giữ danh sách và báo nhẹ', (tester) async {
      repo.rows = rows;
      await open(tester, ReceivablesRoutes.list);
      repo.listError = const ApiException.network();
      final cubit = BlocProvider.of<ReceivablesCubit>(
        tester.element(find.byType(ListView)),
      );
      await cubit.refresh();
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Trần Bảo Bình'), findsOneWidget);
    });

    testWidgets('lọc không ra ai: báo khớp bộ lọc, không báo hết nợ', (
      tester,
    ) async {
      repo.rows = [rows.first];
      await open(tester, ReceivablesRoutes.list);
      await tester.tap(find.text('Trên 60 ngày · 0 đ'));
      await tester.pumpAndSettle();
      expect(find.text('Không có học viên nào khớp bộ lọc.'), findsOneWidget);
      expect(find.text('Không ai còn nợ'), findsNothing);
    });

    testWidgets('lỗi mạng: báo và thử lại tải được', (tester) async {
      repo
        ..listError = const ApiException.network()
        ..rows = rows;
      await open(tester, ReceivablesRoutes.list);
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Trần Bảo Bình'), findsOneWidget);
    });

    testWidgets('chạm học viên mở chi tiết; nút chuông mở cài đặt nhắc nợ', (
      tester,
    ) async {
      repo.rows = rows;
      final router = await open(tester, ReceivablesRoutes.list);
      await tester.tap(find.text('Lê Chi'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('history:c'));
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cài đặt nhắc nợ'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('getSettings'));
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      repo.rows = rows;
      await open(tester, ReceivablesRoutes.list, scale: 1.3);
      expect(find.text('Trần Bảo Bình'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('T11 lịch sử một học viên (AC-2)', () {
    testWidgets('hiện hóa đơn, thanh toán, nhắc nợ của em đó', (tester) async {
      await open(tester, ReceivablesRoutes.student('s1'));
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      expect(find.text('Còn nợ 700.000 đ'), findsOneWidget);
      expect(find.text('TH-25K7Q9 · 10/2026'), findsOneWidget);
      expect(find.text('Còn 700.000 đ / 1.200.000 đ'), findsOneWidget);
      expect(find.text('500.000 đ · Tiền mặt'), findsOneWidget);
      expect(find.textContaining('Ngày thu 05/11/2026'), findsOneWidget);
      expect(
        find.textContaining('Trước hạn 1 ngày · hóa đơn TH-25K7Q9'),
        findsOneWidget,
      );
    });

    testWidgets(
      'chạm hóa đơn mở chi tiết hóa đơn để ghi thu; quay lại tải lại',
      (tester) async {
        billing
          ..invoice = sampleInvoice(
            status: InvoiceStatus.partiallyPaid,
            total: 1200000,
            paid: 500000,
          )
          ..payments = [samplePayment()];
        final router = await open(tester, ReceivablesRoutes.student('s1'));
        await tester.tap(find.text('TH-25K7Q9 · 10/2026'));
        await tester.pumpAndSettle();
        expect(find.byType(InvoicePage), findsOneWidget);
        expect(billing.calls, contains('getInvoice:i1'));
        expect(find.text('Thu một phần'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
        expect(repo.calls.where((c) => c == 'history:s1'), hasLength(2));
      },
    );

    testWidgets('chưa có lịch sử: các mục trống có lời', (tester) async {
      repo.histories['s1'] = sampleHistory(
        invoices: const [],
        payments: const [],
        reminders: const [],
      );
      await open(tester, ReceivablesRoutes.student('s1'));
      expect(find.text('Chưa có hóa đơn.'), findsOneWidget);
      expect(find.text('Chưa có thanh toán.'), findsOneWidget);
      expect(find.text('Chưa có lần nhắc nào.'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      repo.histories['s1'] = sampleHistory(
        name: 'Nguyễn Hoàng Minh Quân Anh',
        enrollments: const [
          ReceivableEnrollment(
            enrollmentId: 'e1',
            classId: 'c1',
            className: 'Toán nâng cao 9A buổi tối',
            dunningEnabled: false,
          ),
        ],
      );
      await open(tester, ReceivablesRoutes.student('s1'), scale: 1.3);
      expect(find.text('Đang tắt nhắc nợ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lỗi tải: báo và thử lại', (tester) async {
      repo.historyError = const ApiException.network();
      await open(tester, ReceivablesRoutes.student('s1'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
    });
  });

  group('bật/tắt nhắc nợ của học viên (AC-4)', () {
    const two = [
      ReceivableEnrollment(
        enrollmentId: 'e1',
        classId: 'c1',
        className: 'Toán 9A',
        dunningEnabled: true,
      ),
      ReceivableEnrollment(
        enrollmentId: 'e2',
        classId: 'c2',
        className: 'Lý 9A',
        dunningEnabled: true,
      ),
    ];

    testWidgets('chi tiết học viên: tắt từng lớp, tắt hết thì hiện đang tắt', (
      tester,
    ) async {
      repo.histories['s1'] = sampleHistory(enrollments: two);
      await open(tester, ReceivablesRoutes.student('s1'));
      expect(find.text('Đang bật nhắc nợ'), findsOneWidget);
      await tester.tap(find.text('Nhắc nợ lớp Toán 9A'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('toggle:e1:false'));
      expect(find.text('Đang bật nhắc nợ'), findsOneWidget);
      await tester.tap(find.text('Nhắc nợ lớp Lý 9A'));
      await tester.pumpAndSettle();
      expect(find.text('Đang tắt nhắc nợ'), findsOneWidget);
      await tester.tap(find.text('Nhắc nợ lớp Lý 9A'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('toggle:e2:true'));
      expect(find.text('Đang bật nhắc nợ'), findsOneWidget);
    });

    testWidgets('lỗi mạng khi tắt: báo lỗi, công tắc giữ nguyên', (
      tester,
    ) async {
      await open(tester, ReceivablesRoutes.student('s1'));
      repo.toggleError = const ApiException.network();
      await tester.tap(find.text('Nhắc nợ lớp Toán 9A'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    Future<void> openRoster(WidgetTester tester) async {
      classes
        ..current = sampleClass(enrolled: 1)
        ..rosterItems = const [
          RosterEntry(
            enrollmentId: 'e1',
            studentId: 's1',
            fullName: 'Nguyễn Văn An',
            studentStatus: 'active',
            joinedOn: '2026-12-14',
          ),
        ];
      await open(tester, ClassesRoutes.detail('c1'));
      await tester.ensureVisible(find.text('Nhắc nợ'));
      await tester.tap(find.text('Nhắc nợ'));
      await tester.pumpAndSettle();
    }

    testWidgets('từ danh sách lớp: hộp thoại tắt rồi bật nhắc nợ của lớp đó', (
      tester,
    ) async {
      repo.histories['s1'] = sampleHistory(enrollments: two);
      await openRoster(tester);
      expect(find.text('Nhắc nợ của Nguyễn Văn An'), findsOneWidget);
      // Chỉ lớp của ghi danh này.
      expect(find.text('Nhắc nợ lớp Toán 9A'), findsOneWidget);
      expect(find.text('Nhắc nợ lớp Lý 9A'), findsNothing);
      await tester.tap(find.text('Nhắc nợ lớp Toán 9A'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('toggle:e1:false'));
      expect(find.text('Đang tắt nhắc nợ'), findsOneWidget);
      await tester.tap(find.text('Nhắc nợ lớp Toán 9A'));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('toggle:e1:true'));
      expect(find.text('Đang bật nhắc nợ'), findsOneWidget);
    });

    testWidgets('từ danh sách lớp: đang tắt hiện ngay khi mở', (tester) async {
      repo.histories['s1'] = sampleHistory(
        enrollments: const [
          ReceivableEnrollment(
            enrollmentId: 'e1',
            classId: 'c1',
            className: 'Toán 9A',
            dunningEnabled: false,
          ),
        ],
      );
      await openRoster(tester);
      expect(find.text('Đang tắt nhắc nợ'), findsOneWidget);
    });

    testWidgets('từ danh sách lớp: lỗi tải báo và thử lại', (tester) async {
      repo.historyError = const ApiException.network();
      await openRoster(tester);
      expect(find.text('Thử lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đang bật nhắc nợ'), findsOneWidget);
    });
  });

  group('cài đặt nhắc nợ (AC-3)', () {
    testWidgets('hiện mặc định -1, 0, 3, 7; chưa sửa thì chưa lưu được', (
      tester,
    ) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      expect(find.text('Trước hạn 1 ngày'), findsOneWidget);
      expect(find.text('Đúng hạn'), findsOneWidget);
      expect(find.text('Sau hạn 3 ngày'), findsOneWidget);
      expect(find.text('Sau hạn 7 ngày'), findsOneWidget);
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(repo.putBodies, isEmpty);
    });

    testWidgets('thêm mốc, tắt công tắc, lưu: PUT đúng thân', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.enterText(find.byType(TextField), '14');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Sau hạn 14 ngày'), findsOneWidget);
      await tester.tap(find.text('Tự động nhắc nợ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(repo.putBodies.single.enabled, isFalse);
      expect(repo.putBodies.single.offsetsDays, [-1, 0, 3, 7, 14]);
      expect(find.text('Đã lưu cài đặt nhắc nợ.'), findsOneWidget);
    });

    testWidgets('nhập mốc sai: báo tại trường, không thêm', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.enterText(find.byType(TextField), '40');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Mốc từ −7 đến 30 ngày.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '3');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Mốc này đã có.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '-');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập một số nguyên.'), findsOneWidget);
    });

    testWidgets('xóa lỗi "không phải số" khi sửa ô nhập', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.enterText(find.byType(TextField), '-');
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập một số nguyên.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '-1');
      await tester.pumpAndSettle();
      expect(find.text('Nhập một số nguyên.'), findsNothing);
    });

    testWidgets(
      'thoát khi còn thay đổi chưa lưu: hỏi; ở lại giữ nguyên, bỏ thì thoát',
      (tester) async {
        await open(tester, '/');
        final router = GoRouter.of(tester.element(find.byType(Scaffold)));
        unawaited(router.push(ReceivablesRoutes.dunningSettings));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Xóa mốc: Sau hạn 7 ngày'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(find.text('Cài đặt nhắc nợ'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bỏ thay đổi'));
        await tester.pumpAndSettle();
        expect(find.text('Mốc nhắc'), findsNothing);
      },
    );

    testWidgets('chưa sửa gì thì thoát thẳng, không hỏi', (tester) async {
      await open(tester, '/');
      final router = GoRouter.of(tester.element(find.byType(Scaffold)));
      unawaited(router.push(ReceivablesRoutes.dunningSettings));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Bỏ thay đổi chưa lưu?'), findsNothing);
      expect(find.text('Mốc nhắc'), findsNothing);
    });

    testWidgets('xóa mốc; đặt lại mặc định', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.tap(find.byTooltip('Xóa mốc: Sau hạn 7 ngày'));
      await tester.pumpAndSettle();
      expect(find.text('Sau hạn 7 ngày'), findsNothing);
      await tester.tap(find.text('Đặt lại mặc định'));
      await tester.pumpAndSettle();
      expect(find.text('Sau hạn 7 ngày'), findsOneWidget);
    });

    testWidgets('lỗi 422 tại mốc: hiện ở trường, giữ bản đang sửa', (
      tester,
    ) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.tap(find.byTooltip('Xóa mốc: Đúng hạn'));
      await tester.pumpAndSettle();
      repo.putError = const ApiException(
        code: ApiErrorCode.validationFailed,
        wireCode: 'VALIDATION_FAILED',
        status: 422,
        fieldErrors: {
          'offsetsDays': ['Mốc không hợp lệ'],
        },
      );
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Mốc không hợp lệ'), findsOneWidget);
      expect(find.text('Đúng hạn'), findsNothing);
      expect(find.text('Đã lưu cài đặt nhắc nợ.'), findsNothing);
    });

    testWidgets('xem trước mẫu tin của một mốc', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.tap(find.text('Xem trước').at(2));
      await tester.pumpAndSettle();
      expect(repo.calls, contains('preview:3'));
      expect(find.text('DayHoc nhắc học phí'), findsOneWidget);
      expect(find.textContaining('mốc 3'), findsOneWidget);
      expect(
        find.text('Dữ liệu mẫu, không phải tên hay số tiền thật.'),
        findsOneWidget,
      );
    });

    testWidgets('lỗi tải: báo và thử lại', (tester) async {
      repo.settingsError = const ApiException.network();
      await open(tester, ReceivablesRoutes.dunningSettings);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Đúng hạn'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      await open(tester, ReceivablesRoutes.dunningSettings, scale: 1.3);
      await tester.tap(find.text('Xem trước').first);
      await tester.pumpAndSettle();
      expect(find.text('DayHoc nhắc học phí'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('nhắc nợ trong chi tiết hóa đơn (AC-5)', () {
    Future<void> openInvoice(
      WidgetTester tester, {
      InvoiceStatus status = InvoiceStatus.issued,
      double scale = 1,
    }) async {
      billing.invoice = sampleInvoice(status: status);
      await open(tester, BillingRoutes.invoice('i1'), scale: scale);
    }

    testWidgets('hóa đơn đã phát hành: đã nhắc lúc nào và lần nhắc tới', (
      tester,
    ) async {
      await openInvoice(tester);
      expect(repo.calls, contains('invoiceDunning:i1'));
      final sent = formatIsoDateTime('2026-11-10T09:00:12+07:00');
      final next = formatIsoDateTime('2026-11-11T09:00:00+07:00');
      expect(find.text('Đã nhắc lúc $sent'), findsOneWidget);
      expect(find.text('Lần nhắc tới: $next'), findsOneWidget);
    });

    testWidgets('đã tắt nhắc: nói rõ lý do, không có lần nhắc tới', (
      tester,
    ) async {
      repo.invoiceDunnings['i1'] = const InvoiceDunning(
        enabled: false,
        disabledReason: DunningDisabledReason.studentDisabled,
        steps: [],
      );
      await openInvoice(tester);
      expect(find.text('Đã tắt nhắc nợ cho học viên này.'), findsOneWidget);
      expect(find.text('Chưa nhắc lần nào.'), findsOneWidget);
      expect(find.textContaining('Lần nhắc tới'), findsNothing);
    });

    testWidgets('ghi thu trên cùng trang: khối nhắc nợ tải lại', (
      tester,
    ) async {
      await openInvoice(tester);
      expect(repo.calls.where((c) => c == 'invoiceDunning:i1'), hasLength(1));
      final full = find.widgetWithText(AppButton, 'Đã thu đủ');
      await tester.ensureVisible(full);
      await tester.tap(full);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận đã thu'));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c == 'invoiceDunning:i1'), hasLength(2));
    });

    testWidgets('mốc có trạng thái lạ: nhãn chung', (tester) async {
      repo.invoiceDunnings['i1'] = InvoiceDunning(
        enabled: true,
        disabledReason: null,
        steps: [sampleStep(status: DunningStepStatus.unknown, sentAt: null)],
      );
      await openInvoice(tester);
      expect(find.textContaining('Trạng thái khác'), findsOneWidget);
      expect(find.textContaining('Lần nhắc tới'), findsNothing);
    });

    testWidgets('bản nháp không có khối nhắc nợ, không gọi API', (
      tester,
    ) async {
      await openInvoice(tester, status: InvoiceStatus.draft);
      expect(find.text('Nhắc nợ'), findsNothing);
      expect(repo.calls.where((c) => c.startsWith('invoiceDunning')), isEmpty);
    });

    testWidgets('lỗi tải nhắc nợ: chỉ khối này báo, hóa đơn vẫn xem được', (
      tester,
    ) async {
      repo.invoiceDunningError = const ApiException.network();
      await openInvoice(tester);
      expect(find.text('Không tải được trạng thái nhắc nợ.'), findsOneWidget);
      expect(find.text('Nguyễn Minh Anh'), findsOneWidget);
      await tester.ensureVisible(find.text('Thử lại'));
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Đã nhắc lúc'), findsOneWidget);
    });

    testWidgets('chữ 130% không vỡ', (tester) async {
      await openInvoice(tester, scale: 1.3);
      expect(find.textContaining('Đã nhắc lúc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
