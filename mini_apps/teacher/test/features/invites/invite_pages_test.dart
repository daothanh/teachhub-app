import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teacher/features/classes/classes_routes.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/classes/data/classes_repository.dart';
import 'package:teacher/features/invites/data/invite_repository.dart';
import 'package:teacher/features/invites/data/invite_sharer.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart';
import '../classes/pump.dart';
import 'fakes.dart';

void main() {
  late FakeClassesRepository classes;
  late FakeInviteRepository invites;
  late FakeInviteSharer sharer;

  setUp(() {
    classes = FakeClassesRepository()
      ..current = sampleClass(enrolled: 2)
      ..rosterItems = [
        entryOf('s1', 'Nguyễn Văn An', [
          guardianOf('g1', GuardianInviteStatus.notInvited),
          guardianOf(
            'g2',
            GuardianInviteStatus.expired,
            relation: 'mother',
            name: 'Lê Thị Lan',
            inviteId: 'old-2',
          ),
        ]),
        entryOf('s2', 'Trần Gia Bảo', [
          guardianOf(
            'g3',
            GuardianInviteStatus.invited,
            relation: 'guardian',
            name: 'Cô Mai',
          ),
          guardianOf('g4', GuardianInviteStatus.activated, name: 'Chú Tư'),
        ]),
        entryOf('s3', 'Phạm Chi', const []),
      ];
    invites = FakeInviteRepository();
    sharer = FakeInviteSharer();
    GetIt.I
      ..registerSingleton<ClassesRepository>(classes)
      ..registerSingleton<InviteRepository>(invites)
      ..registerSingleton<InviteSharer>(sharer);
  });
  tearDown(GetIt.I.reset);

  Future<void> open(
    WidgetTester tester, {
    String? path,
    double scale = 1,
  }) async {
    final router = await pumpRoutes(
      tester,
      classesRoutes('teacher'),
      initial: path ?? ClassesRoutes.detail('c1'),
      textScale: scale,
    );
    addTearDown(router.dispose);
  }

  testWidgets(
    'danh sách học viên hiện trạng thái từng phụ huynh và nút theo trạng thái',
    (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(find.text('Phạm Chi'), 300);

      expect(find.text('Bố: Nguyễn Văn Hải'), findsOneWidget);
      expect(find.text('· Chưa mời'), findsOneWidget);
      expect(find.text('· Hết hạn'), findsOneWidget);
      expect(find.text('· Đã mời'), findsOneWidget);
      expect(find.text('· Đã kích hoạt'), findsOneWidget);
      expect(
        find.text('Chưa có phụ huynh. Chạm tên em để thêm.'),
        findsOneWidget,
      );
      // "Gửi lại link" chỉ cho hết hạn; đã kích hoạt không có nút.
      expect(find.widgetWithText(TextButton, 'Gửi lại link'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Chia sẻ link'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Gửi lại link: resend bằng lời mời cũ, mở chia sẻ kèm link và mã, có QR',
    (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(find.text('Phạm Chi'), 300);
      await tester.tap(find.widgetWithText(TextButton, 'Gửi lại link'));
      await tester.pumpAndSettle();

      expect(invites.calls.single.op, 'resend:old-2');
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('7K3QZ9XM'), findsOneWidget);
      // Bảng chia sẻ mở ngay, tin soạn sẵn có link riêng và mã ngắn.
      final msg = sharer.shared.single;
      expect(msg, contains('Lê Thị Lan'));
      expect(msg, contains('Nguyễn Văn An'));
      expect(msg, contains('https://dayhoc.app/i#t=tok-g-of-old-2'));
      expect(msg, contains('7K3QZ9XM'));

      // Đóng tờ: danh sách tải lại để thấy trạng thái mới.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(classes.calls.where((c) => c == 'get:c1'), hasLength(2));
    },
  );

  testWidgets('Chia sẻ link: phụ huynh chưa mời được tạo lời mời mới', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Chia sẻ link').first);
    await tester.pumpAndSettle();

    expect(invites.calls.single.op, 'create:s1:g1');
    expect(sharer.shared, hasLength(1));
  });

  testWidgets('lỗi tạo lời mời: báo lỗi, Thử lại dùng lại khóa', (
    tester,
  ) async {
    invites.errors.add(const ApiException.network());
    await open(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Chia sẻ link').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Không có mạng. Kiểm tra kết nối rồi thử lại.'),
      findsWidgets,
    );
    expect(sharer.shared, isEmpty);

    await tester.tap(find.text('Thử lại').last);
    await tester.pumpAndSettle();
    expect(invites.calls, hasLength(2));
    expect(invites.calls[1].key, invites.calls[0].key);
    expect(sharer.shared, hasLength(1));
  });

  testWidgets('chữ 200%: danh sách phụ huynh và tờ chia sẻ không vỡ bố cục', (
    tester,
  ) async {
    await open(tester, scale: 2);
    await tester.scrollUntilVisible(find.text('Phạm Chi'), 400);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(TextButton, 'Gửi lại link'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Mời tất cả" mở danh sách link; chia sẻ từng người', (
    tester,
  ) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.text('Mời tất cả phụ huynh chưa kích hoạt'),
      300,
    );
    await tester.tap(find.text('Mời tất cả phụ huynh chưa kích hoạt'));
    await tester.pumpAndSettle();

    expect(find.text('Mời phụ huynh của lớp'), findsOneWidget);
    expect(find.text('Đã tạo 2/2 link'), findsOneWidget);
    expect(invites.calls.map((c) => c.op), ['create:s1:g1', 'resend:old-2']);

    await tester.tap(find.text('Chia sẻ link').first);
    await tester.pumpAndSettle();
    expect(sharer.shared, hasLength(1));
    expect(find.text('Đã mở chia sẻ'), findsOneWidget);
  });

  testWidgets('"Mời tất cả" ẩn khi mọi phụ huynh đã kích hoạt', (tester) async {
    classes.rosterItems = [
      entryOf('s1', 'An', [guardianOf('g1', GuardianInviteStatus.activated)]),
    ];
    await open(tester);
    expect(find.text('Mời tất cả phụ huynh chưa kích hoạt'), findsNothing);
  });

  testWidgets('trang mời tất cả: chữ 200% không vỡ bố cục', (tester) async {
    await open(tester, path: ClassesRoutes.inviteAll('c1'), scale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Đã tạo 2/2 link'), findsOneWidget);
  });

  testWidgets('chia sẻ gửi vùng nút (iPad) và chỉ đánh dấu khi mở được', (
    tester,
  ) async {
    await open(tester, path: ClassesRoutes.inviteAll('c1'));
    sharer.fail = true;
    await tester.tap(find.text('Chia sẻ link').first);
    await tester.pumpAndSettle();
    expect(find.text('Đã mở chia sẻ'), findsNothing);

    sharer.fail = false;
    await tester.tap(find.text('Chia sẻ link').first);
    await tester.pumpAndSettle();
    expect(find.text('Đã mở chia sẻ'), findsOneWidget);
    final origin = sharer.origins.single;
    expect(origin, isNotNull);
    expect(origin!.isEmpty, isFalse);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'mời tất cả dừng vì lỗi mạng: banner và Tiếp tục (chữ $scale)',
      (tester) async {
        classes.rosterItems = [
          for (var n = 1; n <= 5; n++)
            entryOf('s$n', 'HS$n', [
              guardianOf('g$n', GuardianInviteStatus.notInvited),
            ]),
        ];
        invites.errors.addAll([
          for (var n = 0; n < 3; n++) const ApiException.network(),
        ]);
        await open(tester, path: ClassesRoutes.inviteAll('c1'), scale: scale);
        expect(
          find.textContaining('Đã dừng vì lỗi mạng liên tiếp'),
          findsOneWidget,
        );
        expect(invites.calls, hasLength(3));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Tiếp tục'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Đã dừng'), findsNothing);
        expect(find.text('Đã tạo 5/5 link'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
