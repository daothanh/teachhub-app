import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/fees/cubit/fee_override_cubit.dart';
import 'package:teacher/features/fees/data/fee_models.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import 'fake_fee_repository.dart';

void main() {
  late FakeFeeRepository repo;
  late FeeOverrideCubit cubit;
  setUp(() {
    repo = FakeFeeRepository();
    cubit = FeeOverrideCubit(repo, 'e1');
  });
  tearDown(() => cubit.close());

  test('lưu giá riêng: PUT thay toàn bộ, báo saved', () async {
    await cubit.save(
      const FeeOverride(feeAmount: 120000, chargeExcused: false),
    );
    expect(repo.calls, ['put:e1']);
    expect(repo.overrides.single.feeAmount, 120000);
    expect(cubit.state.done, FeeOverrideDone.saved);
  });

  test('clear gửi {} và báo cleared', () async {
    await cubit.clear();
    expect(repo.overrides.single.toJson(), isEmpty);
    expect(cubit.state.done, FeeOverrideDone.cleared);
  });

  test(
    '5 khoản miễn giảm hợp lệ được gửi; mô tả trống bị chặn ở máy',
    () async {
      await cubit.save(
        FeeOverride(
          discounts: [
            for (var i = 0; i < 5; i++)
              FeeDiscount(
                kind: i.isEven
                    ? FeeDiscountKind.percent
                    : FeeDiscountKind.amount,
                description: 'Khoản $i',
                value: 10,
              ),
          ],
        ),
      );
      expect(repo.overrides.single.discounts, hasLength(5));

      await cubit.save(
        const FeeOverride(
          discounts: [
            FeeDiscount(
              kind: FeeDiscountKind.percent,
              description: ' ',
              value: 5,
            ),
          ],
        ),
      );
      expect(cubit.state.clientErrors.keys, ['discounts.0.description']);
      expect(repo.calls, hasLength(1));
    },
  );

  test('422: lỗi tại trường (feeAmount, discounts.N.*)', () async {
    repo.putError = validation({
      'feeAmount': ['Giá phải lớn hơn 0.'],
      'discounts.1.percent': ['Từ 1 đến 100.'],
    });
    await cubit.save(const FeeOverride(feeAmount: 5));
    expect(cubit.state.serverErrors['feeAmount'], ['Giá phải lớn hơn 0.']);
    expect(cubit.state.serverErrors['discounts.1.percent'], isNotNull);
    expect(cubit.state.error, isNull);
    expect(cubit.state.done, isNull);
  });

  test('422 khóa lạ: lỗi chung', () async {
    repo.putError = validation({
      'zzz': ['x'],
    });
    await cubit.save(const FeeOverride(feeAmount: 5));
    expect(cubit.state.error, isNotNull);
    expect(cubit.state.serverErrors, isEmpty);
  });

  test(
    '429: báo lỗi, không tự thử lại, dùng lại khóa idempotency khi bấm lại',
    () async {
      repo.putError = apiErr(ApiErrorCode.rateLimited);
      await cubit.save(const FeeOverride(feeAmount: 5));
      expect(cubit.state.error!.code, ApiErrorCode.rateLimited);
      expect(repo.calls, hasLength(1));
      await cubit.save(const FeeOverride(feeAmount: 5));
      expect(repo.keys[0], repo.keys[1]);
    },
  );

  test('409 chắc chắn thất bại: lần sau dùng khóa mới', () async {
    repo.putError = apiErr(ApiErrorCode.conflictStale);
    await cubit.save(const FeeOverride(feeAmount: 5));
    await cubit.save(const FeeOverride(feeAmount: 5));
    expect(repo.keys[0], isNot(repo.keys[1]));
  });
}
