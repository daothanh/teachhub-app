import 'dart:async';

import 'package:teacher/features/plan/data/plan_models.dart';
import 'package:teacher/features/plan/data/plan_repository.dart';
import 'package:teacher/features/plan/data/purchase_service.dart';

PlanUsage samplePlan({
  bool isPro = false,
  SubscriptionStatus status = SubscriptionStatus.free,
  int? daysLeft,
  String? end,
  bool trialAvailable = true,
  int? maxClasses = 3,
  int? maxStudents = 20,
  int classes = 2,
  int students = 20,
  int readOnlyClasses = 0,
  int readOnlyStudents = 0,
  bool pro = false,
  bool withReportsExport = false,
}) => PlanUsage(
  isPro: isPro,
  status: status,
  currentPeriodEnd: end,
  daysLeft: daysLeft,
  trialAvailable: trialAvailable,
  maxActiveClasses: maxClasses,
  maxActiveStudents: maxStudents,
  activeClasses: classes,
  activeStudents: students,
  readOnlyClasses: readOnlyClasses,
  readOnlyStudents: readOnlyStudents,
  features: {
    'compliance.form02': pro,
    'compliance.form03': pro,
    'revenue.export': pro,
    'lạ.khóa': true,
    if (withReportsExport) 'reports.export': pro,
  },
);

/// Bản giả: ghi khóa idempotency; lỗi và kết quả theo yêu cầu.
class FakePlanRepository implements PlanRepository {
  PlanUsage current = samplePlan();
  PlanUsage afterTrial = samplePlan(
    isPro: true,
    status: SubscriptionStatus.trialing,
    daysLeft: 14,
    end: '2026-12-05T10:15:00+07:00',
    trialAvailable: false,
    maxClasses: null,
    maxStudents: null,
    pro: true,
  );
  Object? usageError;
  Object? trialError;
  Completer<void>? trialGate;
  Completer<void>? usageGate;
  int usageCalls = 0;
  final trialKeys = <String>[];

  @override
  Future<PlanUsage> usage() async {
    usageCalls++;
    final snapshot = current;
    await usageGate?.future;
    if (usageError != null) throw usageError!;
    return snapshot;
  }

  @override
  Future<PlanUsage> startTrial({required String idempotencyKey}) async {
    trialKeys.add(idempotencyKey);
    await trialGate?.future;
    if (trialError != null) throw trialError!;
    return current = afterTrial;
  }
}

class FakePurchaseService implements PurchaseService {
  FakePurchaseService([this.outcome = PurchaseOutcome.purchased, this.price]);
  PurchaseOutcome outcome;
  String? price;
  int calls = 0;
  Object? error;

  @override
  String? get priceLabel => price;

  @override
  Future<PurchaseOutcome> purchasePro() async {
    calls++;
    if (error != null) throw error!;
    return outcome;
  }
}
