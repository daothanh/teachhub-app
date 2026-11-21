import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teacher/features/billing/cubit/billing_periods_cubit.dart'
    show BillingLoad;
import 'package:teacher/features/plan/cubit/plan_cubit.dart';
import 'package:teacher/features/plan/data/plan_models.dart';
import 'package:teacher/features/plan/data/purchase_service.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../classes/fake_classes_repository.dart' show apiError;
import 'fake_plan.dart';

void main() {
  late FakePlanRepository repo;
  late FakePurchaseService purchase;
  late PlanCubit cubit;
  setUp(() {
    repo = FakePlanRepository();
    purchase = FakePurchaseService();
    cubit = PlanCubit(repo, purchase);
  });
  tearDown(() => cubit.close());

  test('load: thành công và lỗi mạng', () async {
    await cubit.load();
    expect(cubit.state.load, BillingLoad.ready);
    expect(cubit.state.usage, repo.current);
    repo.usageError = const ApiException.network();
    await cubit.load();
    expect(cubit.state.load, BillingLoad.failure);
    expect(cubit.state.error!.kind, ApiErrorKind.network);
  });

  test('refresh lỗi: giữ số cũ, báo lỗi nhẹ', () async {
    await cubit.load();
    repo.usageError = const ApiException.network();
    await cubit.refresh();
    expect(cubit.state.load, BillingLoad.ready);
    expect(cubit.state.usage, isNotNull);
    expect(cubit.state.actionError, isNotNull);
  });

  group('dùng thử', () {
    test('thành công: Pro dùng thử, đóng khóa idempotency', () async {
      await cubit.load();
      await cubit.startTrial();
      expect(cubit.state.usage!.status, SubscriptionStatus.trialing);
      expect(cubit.state.notice, PlanNotice.trialStarted);
      expect(cubit.state.busy, isFalse);
      // Lệnh sau là lệnh mới.
      repo.trialError = const ApiException.network();
      await cubit.startTrial();
      expect(repo.trialKeys, hasLength(2));
      expect(repo.trialKeys[1], isNot(repo.trialKeys[0]));
    });

    test('lỗi mạng: thử lại dùng đúng khóa cũ', () async {
      await cubit.load();
      repo.trialError = const ApiException.network();
      await cubit.startTrial();
      expect(cubit.state.actionError!.kind, ApiErrorKind.network);
      repo.trialError = null;
      await cubit.startTrial();
      expect(repo.trialKeys, hasLength(2));
      expect(repo.trialKeys[1], repo.trialKeys[0]);
      expect(cubit.state.usage!.isPro, isTrue);
    });

    test('422 TRIAL_ALREADY_USED: tải lại, nút dùng thử biến mất', () async {
      repo.current = samplePlan();
      await cubit.load();
      repo.current = samplePlan(trialAvailable: false);
      repo.trialError = apiError(ApiErrorCode.trialAlreadyUsed);
      await cubit.startTrial();
      expect(cubit.state.actionError!.code, ApiErrorCode.trialAlreadyUsed);
      expect(cubit.state.usage!.trialAvailable, isFalse);
      // Lỗi chắc chắn: lần sau khóa mới.
      repo.trialError = null;
      await cubit.startTrial();
      expect(repo.trialKeys[1], isNot(repo.trialKeys[0]));
    });

    test('409 đang Pro: tải lại gói hiện tại', () async {
      await cubit.load();
      repo.current = repo.afterTrial;
      repo.trialError = apiError(ApiErrorCode.conflictStale);
      await cubit.startTrial();
      expect(cubit.state.actionError!.code, ApiErrorCode.conflictStale);
      expect(cubit.state.usage!.isPro, isTrue);
    });

    test('bấm đúp khi đang gửi chỉ gửi một lần', () async {
      await cubit.load();
      repo.trialGate = Completer<void>();
      final first = cubit.startTrial();
      await cubit.startTrial();
      repo.trialGate!.complete();
      await first;
      expect(repo.trialKeys, hasLength(1));
    });
  });

  group('mua Pro (IAP)', () {
    test('thành công: báo đang kích hoạt và tải lại gói', () async {
      await cubit.load();
      final seen = <PlanNotice?>[];
      final sub = cubit.stream.listen((s) => seen.add(s.notice));
      await cubit.purchase();
      await sub.cancel();
      expect(purchase.calls, 1);
      expect(seen, contains(PlanNotice.purchasePending));
      expect(repo.usageCalls, 2);
    });

    test('chưa có sản phẩm / lỗi / hủy', () async {
      await cubit.load();
      purchase.outcome = PurchaseOutcome.unavailable;
      await cubit.purchase();
      expect(cubit.state.notice, PlanNotice.purchaseUnavailable);
      purchase.outcome = PurchaseOutcome.failed;
      await cubit.purchase();
      expect(cubit.state.notice, PlanNotice.purchaseFailed);
      purchase.outcome = PurchaseOutcome.cancelled;
      await cubit.purchase();
      expect(cubit.state.notice, isNull);
      expect(cubit.state.busy, isFalse);
    });

    test('bản tạm trả unavailable và không có giá', () async {
      const stub = StubPurchaseService();
      expect(await stub.purchasePro(), PurchaseOutcome.unavailable);
      expect(stub.priceLabel, isNull);
    });
  });
}
