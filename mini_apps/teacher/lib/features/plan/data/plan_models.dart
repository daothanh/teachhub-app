import 'package:equatable/equatable.dart';

/// Mô hình gói khớp `contracts/openapi.json` (PlanUsage). Chỉ đọc trường T14
/// dùng; `proPriceVnd` và `pendingBankTransferOrder` bỏ qua vì chuyển khoản mua
/// gói chỉ ở web (R6) và giá trong app lấy từ store.

/// `SubscriptionStatus`; giá trị lạ coi như `free`.
enum SubscriptionStatus {
  free,
  trialing,
  active,
  expired;

  static SubscriptionStatus fromWire(String? v) => switch (v) {
    'trialing' => trialing,
    'active' => active,
    'expired' => expired,
    _ => free,
  };
}

/// Khóa feature flag mà app biết nhãn (Spec §4.4); khóa lạ bị bỏ qua.
const knownPlanFeatures = [
  'compliance.form02',
  'compliance.form03',
  'revenue.export',
  'reports.export',
];

class PlanUsage extends Equatable {
  const PlanUsage({
    required this.isPro,
    required this.status,
    required this.currentPeriodEnd,
    required this.daysLeft,
    required this.trialAvailable,
    required this.maxActiveClasses,
    required this.maxActiveStudents,
    required this.activeClasses,
    required this.activeStudents,
    required this.readOnlyClasses,
    required this.readOnlyStudents,
    required this.features,
  });

  factory PlanUsage.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>;
    final limits = json['limits'] as Map<String, dynamic>;
    final usage = json['usage'] as Map<String, dynamic>;
    final readOnly = json['readOnly'] as Map<String, dynamic>;
    return PlanUsage(
      isPro: plan['code'] == 'pro',
      status: SubscriptionStatus.fromWire(plan['status'] as String?),
      currentPeriodEnd: plan['currentPeriodEnd'] as String?,
      daysLeft: plan['daysLeft'] as int?,
      trialAvailable: plan['trialAvailable'] as bool,
      maxActiveClasses: limits['maxActiveClasses'] as int?,
      maxActiveStudents: limits['maxActiveStudents'] as int?,
      activeClasses: usage['activeClasses'] as int,
      activeStudents: usage['activeStudents'] as int,
      readOnlyClasses: readOnly['classCount'] as int,
      readOnlyStudents: readOnly['studentCount'] as int,
      features: {
        for (final f in json['features'] as List)
          (f as Map<String, dynamic>)['key'] as String: f['enabled'] as bool,
      },
    );
  }

  /// `plan.code == pro`: đang dùng thử hoặc Pro trả phí còn hạn.
  final bool isPro;
  final SubscriptionStatus status;

  /// Ngày giờ hết hạn theo múi giờ tenant; `null` khi Miễn phí.
  final String? currentPeriodEnd;
  final int? daysLeft;

  /// `false` thì ẩn nút "Dùng thử 14 ngày" (đã dùng hoặc đang Pro).
  final bool trialAvailable;

  /// `null` = không giới hạn (Pro).
  final int? maxActiveClasses;
  final int? maxActiveStudents;
  final int activeClasses;
  final int activeStudents;
  final int readOnlyClasses;
  final int readOnlyStudents;

  /// Khóa feature flag → đang bật.
  final Map<String, bool> features;

  bool get hasReadOnly => readOnlyClasses > 0 || readOnlyStudents > 0;

  /// Ngày hết hạn `dd/MM/yyyy` theo múi giờ tenant (10 ký tự đầu của ISO).
  String? get endDate {
    final s = currentPeriodEnd;
    if (s == null || s.length < 10) return null;
    return '${s.substring(8, 10)}/${s.substring(5, 7)}/${s.substring(0, 4)}';
  }

  @override
  List<Object?> get props => [
    isPro, status, currentPeriodEnd, daysLeft, trialAvailable, //
    maxActiveClasses, maxActiveStudents, activeClasses, activeStudents,
    readOnlyClasses, readOnlyStudents, features,
  ];
}
