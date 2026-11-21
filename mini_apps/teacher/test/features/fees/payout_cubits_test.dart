import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/fees/cubit/payout_account_form_cubit.dart';
import 'package:teacher/features/fees/cubit/payout_accounts_cubit.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_fee_repository.dart';

const _input = PayoutAccountInput(
  bankBin: '970436',
  accountNo: '0123456789',
  accountName: 'NGUYEN VAN A',
);

void main() {
  group('PayoutAccountsCubit', () {
    late FakeFeeRepository repo;
    setUp(() => repo = FakeFeeRepository());

    test('load: tải danh sách; lỗi → failure', () async {
      repo.accounts = [sampleAccount()];
      final c = PayoutAccountsCubit(repo);
      await c.load();
      expect(c.state.load, PayoutLoad.ready);
      expect(c.state.accounts.single.accountNoMasked, '******6789');

      repo.listError = const ApiException.network();
      await c.load();
      expect(c.state.load, PayoutLoad.failure);
      expect(c.state.error!.kind, ApiErrorKind.network);
      await c.close();
    });

    test(
      'cần OTP: đặt chính tài khoản phụ; xóa tài khoản chính khi còn khác',
      () async {
        repo.accounts = [
          sampleAccount(),
          sampleAccount(id: 'a2', primary: false),
        ];
        final c = PayoutAccountsCubit(repo);
        await c.load();
        expect(c.setPrimaryNeedsOtp('a2'), isTrue);
        expect(c.setPrimaryNeedsOtp('a1'), isFalse);
        expect(c.deleteNeedsOtp('a1'), isTrue);
        expect(c.deleteNeedsOtp('a2'), isFalse);
        await c.close();

        repo.accounts = [sampleAccount()];
        final single = PayoutAccountsCubit(repo);
        await single.load();
        expect(single.deleteNeedsOtp('a1'), isFalse, reason: 'chính duy nhất');
        await single.close();
      },
    );

    test('đặt chính và xóa gửi otpCode lên; OTP sai báo lỗi', () async {
      repo.accounts = [
        sampleAccount(),
        sampleAccount(id: 'a2', primary: false),
      ];
      final c = PayoutAccountsCubit(repo);
      await c.load();
      await c.setPrimary('a2', otpCode: '123456');
      expect(repo.sentOtps.last, '123456');
      repo.deleteError = apiErr(ApiErrorCode.otpInvalid);
      await c.delete('a2', otpCode: '000000');
      expect(c.state.error!.code, ApiErrorCode.otpInvalid);
      expect(repo.sentOtps.last, '000000');
      await c.close();
    });

    test('sendOtp: gửi mã; lỗi trả về, không kẹt busy', () async {
      final c = PayoutAccountsCubit(repo);
      expect(await c.sendOtp(), isNull);
      expect(repo.calls, contains('otp'));
      repo.otpError = apiErr(ApiErrorCode.rateLimited);
      final err = await c.sendOtp();
      expect(err!.code, ApiErrorCode.rateLimited);
      expect(c.state.busy, isFalse);
      await c.close();
    });

    test('tối đa 5: canAdd hết khi đủ 5', () async {
      repo.accounts = [
        for (var i = 0; i < 5; i++) sampleAccount(id: 'a$i', primary: i == 0),
      ];
      final c = PayoutAccountsCubit(repo);
      await c.load();
      expect(c.state.canAdd, isFalse);
      await c.close();
    });

    test(
      'S2: xóa thành công nhưng tải lại lỗi → bỏ tài khoản tại máy, không báo lỗi ghi',
      () async {
        repo.accounts = [
          sampleAccount(),
          sampleAccount(id: 'a2', primary: false),
        ];
        final c = PayoutAccountsCubit(repo);
        await c.load();
        repo.listError = const ApiException.network();
        await c.delete('a2');
        expect(c.state.load, PayoutLoad.ready);
        expect(c.state.accounts.map((a) => a.id), ['a1']);
        expect(c.state.error, isNull);
        expect(c.state.notice, PayoutNotice.deleted);
        expect(c.state.busy, isFalse);
        await c.close();
      },
    );

    test(
      'S2: đặt chính thành công nhưng tải lại lỗi → đánh dấu chính tại máy',
      () async {
        repo.accounts = [
          sampleAccount(),
          sampleAccount(id: 'a2', primary: false),
        ];
        final c = PayoutAccountsCubit(repo);
        await c.load();
        repo.listError = const ApiException.network();
        await c.setPrimary('a2');
        expect(c.state.accounts.map((a) => (a.id, a.isPrimary)), [
          ('a1', false),
          ('a2', true),
        ]);
        expect(c.state.error, isNull);
        await c.close();
      },
    );

    test(
      'S2: xóa tài khoản chính, tải lại lỗi → trạng thái tải lỗi để thử lại',
      () async {
        repo.accounts = [
          sampleAccount(),
          sampleAccount(id: 'a2', primary: false),
        ];
        final c = PayoutAccountsCubit(repo);
        await c.load();
        repo.listError = const ApiException.network();
        await c.delete('a1');
        expect(c.state.load, PayoutLoad.failure);
        repo.listError = null;
        await c.load();
        expect(c.state.accounts.single.id, 'a2');
        await c.close();
      },
    );

    test('đặt chính: PATCH isPrimary, không OTP, tải lại', () async {
      repo.accounts = [
        sampleAccount(),
        sampleAccount(id: 'a2', primary: false),
      ];
      final c = PayoutAccountsCubit(repo);
      await c.load();
      await c.setPrimary('a2');
      expect(repo.calls, contains('update:a2:primary'));
      expect(repo.sentOtps.last, isNull);
      expect(
        c.state.accounts.firstWhere((a) => a.id == 'a2').isPrimary,
        isTrue,
      );
      expect(c.state.notice, PayoutNotice.primarySet);
      await c.close();
    });

    test(
      'xóa: DELETE rồi tải lại; lỗi 429 giữ danh sách và báo lỗi, không thử lại',
      () async {
        repo.accounts = [
          sampleAccount(),
          sampleAccount(id: 'a2', primary: false),
        ];
        final c = PayoutAccountsCubit(repo);
        await c.load();
        repo.deleteError = apiErr(ApiErrorCode.rateLimited);
        await c.delete('a2');
        expect(c.state.error!.code, ApiErrorCode.rateLimited);
        expect(c.state.accounts, hasLength(2));
        expect(repo.calls.where((x) => x == 'delete:a2'), hasLength(1));

        repo.deleteError = null;
        await c.delete('a2');
        expect(c.state.accounts.single.id, 'a1');
        expect(c.state.notice, PayoutNotice.deleted);
        await c.close();
      },
    );
  });

  group('PayoutAccountFormCubit: thêm mới', () {
    late FakeFeeRepository repo;
    late PayoutAccountFormCubit c;
    setUp(() {
      repo = FakeFeeRepository();
      c = PayoutAccountFormCubit(repo);
    });
    tearDown(() => c.close());

    test(
      'submit gửi OTP trước, nhập mã rồi mới tạo; state không giữ số tài khoản',
      () async {
        await c.submit(_input);
        expect(repo.calls, ['otp']);
        expect(c.state.step, PayoutStep.code);
        expect(c.state.codeSent, isTrue);

        await c.confirm('482913');
        expect(repo.calls, ['otp', 'create']);
        expect(repo.sentOtps.single, '482913');
        expect(c.state.saved!.accountNoMasked, '******6789');
        expect(c.state.toString(), isNot(contains('0123456789')));
        expect(c.state.saved.toString(), isNot(contains('0123456789')));
      },
    );

    test(
      'OTP sai: ở lại bước nhập mã, báo OTP_INVALID, nhập lại được',
      () async {
        await c.submit(_input);
        repo.createError = apiErr(ApiErrorCode.otpInvalid);
        await c.confirm('000000');
        expect(c.state.step, PayoutStep.code);
        expect(c.state.error!.code, ApiErrorCode.otpInvalid);
        expect(c.state.saved, isNull);

        repo.createError = null;
        await c.confirm('482913');
        expect(c.state.saved, isNotNull);
        // Mã khác là lệnh mới: khóa idempotency khác.
        expect(repo.keys[0], isNot(repo.keys[1]));
      },
    );

    test('OTP bị khóa: báo OTP_LOCKED, không tự gửi lại', () async {
      await c.submit(_input);
      repo.createError = apiErr(ApiErrorCode.otpLocked);
      await c.confirm('000000');
      expect(c.state.error!.code, ApiErrorCode.otpLocked);
      expect(c.state.step, PayoutStep.code);
      expect(repo.calls.where((x) => x == 'otp'), hasLength(1));
    });

    test('429 khi gửi mã: ở lại form, báo RATE_LIMITED', () async {
      repo.otpError = apiErr(ApiErrorCode.rateLimited);
      await c.submit(_input);
      expect(c.state.step, PayoutStep.form);
      expect(c.state.error!.code, ApiErrorCode.rateLimited);
      expect(repo.calls, ['otp']);
    });

    test('422 ở accountNo: về form, lỗi tại trường', () async {
      await c.submit(_input);
      repo.createError = validation({
        'accountNo': ['Số tài khoản không hợp lệ.'],
      });
      await c.confirm('482913');
      expect(c.state.step, PayoutStep.form);
      expect(c.state.serverErrors['accountNo'], isNotNull);
      expect(c.state.error, isNull);
    });

    test('422 ở otpCode: ở lại bước mã', () async {
      await c.submit(_input);
      repo.createError = validation({
        'otpCode': ['Mã gồm 6 số.'],
      });
      await c.confirm('12');
      expect(c.state.step, PayoutStep.code);
      expect(c.state.serverErrors['otpCode'], isNotNull);
    });

    test(
      'kiểm tra ở máy: thiếu ngân hàng, số tài khoản ngắn → chưa gọi API',
      () async {
        await c.submit(
          const PayoutAccountInput(
            bankBin: '',
            accountNo: '123',
            accountName: 'A',
          ),
        );
        expect(
          c.state.clientErrors.keys,
          containsAll(['bankBin', 'accountNo']),
        );
        expect(repo.calls, isEmpty);
      },
    );

    test('gửi lại mã: vẫn ở bước mã, gọi OTP lần hai', () async {
      await c.submit(_input);
      await c.sendCode();
      expect(repo.calls, ['otp', 'otp']);
      expect(c.state.step, PayoutStep.code);
    });
  });

  group('PayoutAccountFormCubit: sửa', () {
    late FakeFeeRepository repo;
    final editing = sampleAccount();
    setUp(() => repo = FakeFeeRepository()..accounts = [editing]);

    test('chỉ đổi tên chủ tài khoản: PATCH không cần OTP', () async {
      final c = PayoutAccountFormCubit(repo, editing: editing);
      await c.submit(
        const PayoutAccountInput(
          bankBin: '970436',
          accountNo: '',
          accountName: 'NGUYEN VAN B',
        ),
      );
      expect(repo.calls, ['update:a1:name']);
      expect(repo.sentOtps.single, isNull);
      expect(c.state.saved!.accountName, 'NGUYEN VAN B');
      await c.close();
    });

    test('không đổi gì: không gọi API', () async {
      final c = PayoutAccountFormCubit(repo, editing: editing);
      await c.submit(
        const PayoutAccountInput(
          bankBin: '970436',
          accountNo: '',
          accountName: 'NGUYEN VAN A',
        ),
      );
      expect(repo.calls, isEmpty);
      expect(c.state.saved, editing);
      await c.close();
    });

    test('đổi số tài khoản: qua OTP, PATCH kèm otpCode', () async {
      final c = PayoutAccountFormCubit(repo, editing: editing);
      await c.submit(
        const PayoutAccountInput(
          bankBin: '970436',
          accountNo: '9876543210',
          accountName: 'NGUYEN VAN A',
        ),
      );
      expect(repo.calls, ['otp']);
      await c.confirm('111222');
      expect(repo.calls.last, 'update:a1:no');
      expect(repo.sentOtps.last, '111222');
      await c.close();
    });

    test('đổi ngân hàng mà không nhập lại số tài khoản: chặn ở máy', () async {
      final c = PayoutAccountFormCubit(repo, editing: editing);
      await c.submit(
        const PayoutAccountInput(
          bankBin: '970415',
          accountNo: '',
          accountName: 'NGUYEN VAN A',
        ),
      );
      expect(c.state.clientErrors['accountNo'], PayoutFieldError.required);
      expect(repo.calls, isEmpty);
      await c.close();
    });
  });
}
