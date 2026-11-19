import 'package:app/features/invite/invite_cubit.dart';
import 'package:app/features/invite/invite_entry_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'invite_fakes.dart';

void main() {
  late FakeInviteRepository repo;
  late FakeMemberships memberships;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = FakeInviteRepository();
    memberships = FakeMemberships(await SharedPreferences.getInstance());
  });

  group('InviteCubit (link / QR)', () {
    InviteCubit make(consent) => InviteCubit(
      repository: repo,
      memberships: memberships,
      consent: consent,
      token: 'TOKEN',
    );

    test('load: thẻ lời mời; 410 → invalid', () async {
      final c = make(fakeConsent());
      repo.previews.add(samplePreview);
      await c.load();
      expect(c.state.phase, InvitePhase.ready);
      expect(c.state.preview?.studentGivenName, 'Anh');

      repo.previews.add(apiError(410, 'INVITE_INVALID'));
      await c.load();
      expect(c.state.phase, InvitePhase.invalid);
    });

    test(
      'accept: mở vai trò Phụ huynh, báo đã đồng ý, bỏ token sau khi dùng',
      () async {
        final consent = fakeConsent();
        final c = make(consent);
        repo.previews.add(samplePreview);
        await c.load();
        repo.accepts.add(FakeInviteRepository.accepted);
        await c.accept();
        expect(c.state.phase, InvitePhase.accepted);
        expect(memberships.selected, ['m-p']);
        expect(consent.state.accepted, isTrue);

        await c.accept(); // token đã bỏ: không gọi API lần nữa
        expect(repo.calls.where((x) => x.startsWith('accept')).length, 1);
      },
    );

    test(
      '403 CONSENT_REQUIRED → consentRequired; đồng ý xong nhận lại được',
      () async {
        final c = make(fakeConsent());
        repo.previews.add(samplePreview);
        await c.load();
        repo.accepts
          ..add(
            apiError(403, 'CONSENT_REQUIRED', details: {'termsVersion': 'v1'}),
          )
          ..add(FakeInviteRepository.accepted);
        await c.accept();
        expect(c.state.phase, InvitePhase.consentRequired);
        expect(c.state.preview, isNotNull);

        await c.accept();
        expect(c.state.phase, InvitePhase.accepted);
      },
    );

    test('thoát màn đồng ý → quay lại thẻ lời mời', () async {
      final c = make(fakeConsent());
      repo.previews.add(samplePreview);
      await c.load();
      repo.accepts.add(apiError(403, 'CONSENT_REQUIRED'));
      await c.accept();
      c.consentDeclined();
      expect(c.state.phase, InvitePhase.ready);
    });

    test(
      '410 khi nhận → invalid và bỏ token; lỗi khác → failed, thử lại được',
      () async {
        final c = make(fakeConsent());
        repo.previews.add(samplePreview);
        await c.load();
        repo.accepts.add(apiError(429, 'RATE_LIMITED'));
        await c.accept();
        expect(c.state.phase, InvitePhase.failed);
        expect(c.state.errorCode, ApiErrorCode.rateLimited);

        repo.accepts.add(apiError(410, 'INVITE_INVALID'));
        await c.accept();
        expect(c.state.phase, InvitePhase.invalid);
        await c.accept();
        expect(repo.calls.where((x) => x.startsWith('accept')).length, 2);
      },
    );
  });

  group('InviteEntryCubit (mã ngắn)', () {
    InviteEntryCubit make(consent) => InviteEntryCubit(
      repository: repo,
      memberships: memberships,
      consent: consent,
    );

    test('redeem thành công', () async {
      final consent = fakeConsent();
      final c = make(consent);
      repo.redeems.add(FakeInviteRepository.accepted);
      await c.redeem('7K3QZ9XM');
      expect(c.state.phase, InviteEntryPhase.accepted);
      expect(memberships.selected, ['m-p']);
      expect(consent.state.accepted, isTrue);
    });

    test('410 → invalid (cùng một thông báo)', () async {
      final c = make(fakeConsent());
      repo.redeems.add(apiError(410, 'INVITE_INVALID'));
      await c.redeem('AAAAAAAA');
      expect(c.state.phase, InviteEntryPhase.invalid);
    });

    test(
      '429 INVITE_CODE_LOCKED: khóa tới hết retryAfter, trong lúc khóa không gọi API',
      () async {
        final c = make(fakeConsent());
        repo.redeems.add(
          apiError(429, 'INVITE_CODE_LOCKED', details: {'retryAfterSec': 1}),
        );
        await c.redeem('AAAAAAAA');
        expect(c.state.phase, InviteEntryPhase.locked);
        expect(c.state.lockedUntil, isNotNull);

        await c.redeem('BBBBBBBB');
        expect(repo.calls, ['redeem:AAAAAAAA']);

        await Future<void>.delayed(const Duration(milliseconds: 1100));
        expect(c.state.phase, InviteEntryPhase.idle);
        repo.redeems.add(FakeInviteRepository.accepted);
        await c.redeem('CCCCCCCC');
        expect(c.state.phase, InviteEntryPhase.accepted);
      },
    );

    test('429 khóa không kèm retryAfter: mặc định 15 phút', () async {
      final now = DateTime(2026, 12, 1, 8);
      final c = InviteEntryCubit(
        repository: repo,
        memberships: memberships,
        consent: fakeConsent(),
        clock: () => now,
      );
      repo.redeems.add(apiError(429, 'INVITE_CODE_LOCKED'));
      await c.redeem('AAAAAAAA');
      expect(c.state.lockedUntil, now.add(const Duration(minutes: 15)));
      await c.close();
    });

    test(
      'CONSENT_REQUIRED: giữ mã, đồng ý xong redeem() lại không cần nhập lại',
      () async {
        final c = make(fakeConsent());
        repo.redeems
          ..add(apiError(403, 'CONSENT_REQUIRED'))
          ..add(FakeInviteRepository.accepted);
        await c.redeem('7K3QZ9XM');
        expect(c.state.phase, InviteEntryPhase.consentRequired);
        await c.redeem();
        expect(repo.calls, ['redeem:7K3QZ9XM', 'redeem:7K3QZ9XM']);
        expect(c.state.phase, InviteEntryPhase.accepted);
      },
    );

    test('thoát màn đồng ý: bỏ mã đang giữ', () async {
      final c = make(fakeConsent());
      repo.redeems.add(apiError(403, 'CONSENT_REQUIRED'));
      await c.redeem('7K3QZ9XM');
      c.consentDeclined();
      await c.redeem();
      expect(repo.calls.length, 1);
      expect(c.state.phase, InviteEntryPhase.idle);
    });
  });
}
