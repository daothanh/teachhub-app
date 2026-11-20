import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/classes/data/class_models.dart';
import 'package:teacher/features/invites/cubit/bulk_invite_cubit.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart';
import 'fakes.dart';

void main() {
  late FakeClassesRepository classes;
  late FakeInviteRepository invites;
  setUp(() {
    classes = FakeClassesRepository()
      ..rosterItems = [
        entryOf('s1', 'An', [
          guardianOf('g1', GuardianInviteStatus.notInvited),
          guardianOf('g2', GuardianInviteStatus.activated, relation: 'mother'),
        ]),
        entryOf('s2', 'Bình', [
          guardianOf('g3', GuardianInviteStatus.invited),
          guardianOf('g4', GuardianInviteStatus.expired, inviteId: 'old-4'),
        ]),
        entryOf('s3', 'Chi', const []),
      ];
    invites = FakeInviteRepository();
  });

  BulkInviteCubit make() => BulkInviteCubit(classes, invites, 'c1');

  test(
    'chỉ mời chưa mời và hết hạn: tạo mới / gửi lại, bỏ qua còn hạn và đã kích hoạt',
    () async {
      final cubit = make();
      await cubit.start();

      expect(cubit.state.status, BulkInviteStatus.done);
      expect(cubit.state.items.map((i) => i.guardian.id), ['g1', 'g4']);
      expect(invites.calls.map((c) => c.op), ['create:s1:g1', 'resend:old-4']);
      expect(cubit.state.ready, 2);
      expect(cubit.state.items.every((i) => i.link != null), isTrue);
      await cubit.close();
    },
  );

  test(
    'một người lỗi không chặn người khác; thử lại giữ khóa khi lỗi mạng',
    () async {
      invites.errors.add(const ApiException.network());
      final cubit = make();
      await cubit.start();

      expect(cubit.state.items[0].error, isNotNull);
      expect(cubit.state.items[1].link, isNotNull);
      final firstKey = invites.calls[0].key;

      await cubit.retry(0);
      expect(cubit.state.items[0].link, isNotNull);
      expect(cubit.state.items[0].error, isNull);
      // Lỗi mạng: gửi lại cùng khóa để server phát lại thay vì tạo hai lời mời.
      expect(invites.calls.last.key, firstKey);
      await cubit.close();
    },
  );

  test('lỗi chắc chắn (409) thì lần thử lại dùng khóa mới', () async {
    invites.errors.add(conflict());
    final cubit = make();
    await cubit.start();
    final firstKey = invites.calls[0].key;
    await cubit.retry(0);
    expect(invites.calls.last.key, isNot(firstKey));
    await cubit.close();
  });

  test('lớp không còn ai cần mời: danh sách rỗng, không gọi API', () async {
    classes.rosterItems = [
      entryOf('s1', 'An', [guardianOf('g1', GuardianInviteStatus.activated)]),
    ];
    final cubit = make();
    await cubit.start();
    expect(cubit.state.items, isEmpty);
    expect(invites.calls, isEmpty);
    await cubit.close();
  });

  test('tải danh sách lớp lỗi: failure', () async {
    final cubit = BulkInviteCubit(_FailingRoster(), invites, 'c1');
    await cubit.start();
    expect(cubit.state.status, BulkInviteStatus.failure);
    await cubit.close();
  });

  test('markShared đánh dấu đã gửi', () async {
    final cubit = make();
    await cubit.start();
    cubit.markShared(0);
    expect(cubit.state.items[0].shared, isTrue);
    expect(cubit.state.items[1].shared, isFalse);
    await cubit.close();
  });

  group('dừng khi lỗi liên tiếp', () {
    void manyGuardians() => classes.rosterItems = [
      for (var n = 1; n <= 6; n++)
        entryOf('s$n', 'HS$n', [
          guardianOf('g$n', GuardianInviteStatus.notInvited),
        ]),
    ];

    test(
      '3 lỗi mạng liên tiếp: dừng, không gọi tiếp; Tiếp tục làm nốt',
      () async {
        manyGuardians();
        invites.errors.addAll([
          for (var n = 0; n < 3; n++) const ApiException.network(),
        ]);
        final cubit = make();
        await cubit.start();

        expect(cubit.state.status, BulkInviteStatus.paused);
        expect(cubit.state.retryAfter, isNull);
        expect(invites.calls, hasLength(3));
        expect(cubit.state.ready, 0);

        await cubit.resume();
        expect(cubit.state.status, BulkInviteStatus.done);
        expect(cubit.state.ready, 6);
        // Ba người lỗi thử lại cùng khóa.
        expect(invites.calls[3].key, invites.calls[0].key);
        await cubit.close();
      },
    );

    test('3 lỗi 429 liên tiếp: dừng và đọc retryAfter', () async {
      manyGuardians();
      invites.errors.addAll([
        for (var n = 0; n < 3; n++)
          ApiException.fromResponse(429, {
            'code': 'RATE_LIMITED',
            'message': 'x',
            'details': {'retryAfterSec': 30},
          }),
      ]);
      final cubit = make();
      await cubit.start();
      expect(cubit.state.status, BulkInviteStatus.paused);
      expect(cubit.state.retryAfter, const Duration(seconds: 30));
      expect(invites.calls, hasLength(3));
      await cubit.close();
    });

    test('lỗi xen kẽ thành công không đủ ba liên tiếp: chạy hết', () async {
      manyGuardians();
      invites.errors.addAll([
        const ApiException.network(),
        const ApiException.network(),
      ]);
      final cubit = make();
      await cubit.start();
      // Hai lỗi đầu, rồi thành công ở người thứ 3 trở đi.
      expect(cubit.state.status, BulkInviteStatus.done);
      expect(cubit.state.ready, 4);
      await cubit.close();
    });

    test('lỗi dứt khoát (409) không tính vào chuỗi dừng', () async {
      manyGuardians();
      invites.errors.addAll([for (var n = 0; n < 3; n++) conflict()]);
      final cubit = make();
      await cubit.start();
      expect(cubit.state.status, BulkInviteStatus.done);
      expect(cubit.state.ready, 3);
      await cubit.close();
    });
  });
}

class _FailingRoster extends FakeClassesRepository {
  @override
  Future<List<RosterEntry>> roster(String id) async =>
      throw const ApiException.network();
}
