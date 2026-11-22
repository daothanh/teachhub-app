import 'package:equatable/equatable.dart';

/// Khóa bước theo thứ tự của hợp đồng (`Onboarding.steps[].step`).
///
/// Onboarding còn 3 bước (22/11/2026). Server vẫn trả `payout_account` và
/// `compliance_checklist`: [fromWire] coi là bước lạ nên app bỏ qua, xong
/// bước 3 thì [Onboarding.currentStep] là `null`.
enum OnboardingStep {
  createClass('create_class'),
  addStudents('add_students'),
  setSchedule('set_schedule');

  const OnboardingStep(this.wire);
  final String wire;

  /// Bước 1 không được bỏ qua (US-0.2 AC2).
  bool get skippable => this != createClass;

  static OnboardingStep? fromWire(String? wire) =>
      values.where((s) => s.wire == wire).firstOrNull;
}

enum OnboardingStatus {
  pending,
  done,
  skipped;

  /// Giá trị lạ (server mới hơn app) coi như chưa làm.
  static OnboardingStatus fromWire(String wire) =>
      values.where((s) => s.name == wire).firstOrNull ?? pending;
}

class Onboarding extends Equatable {
  const Onboarding({required this.steps, required this.currentStep});

  /// Bước lạ (server mới hơn app) bị bỏ qua.
  factory Onboarding.fromJson(Map<String, dynamic> json) {
    final steps = <OnboardingStep, OnboardingStatus>{};
    for (final raw in json['steps'] as List) {
      final step = OnboardingStep.fromWire((raw as Map)['step'] as String);
      if (step != null) {
        steps[step] = OnboardingStatus.fromWire(raw['status'] as String);
      }
    }
    final wire = json['currentStep'] as String?;
    return Onboarding(
      steps: steps,
      currentStep: wire == null
          ? null
          : OnboardingStep.fromWire(wire) ??
                steps.entries
                    .where((e) => e.value == OnboardingStatus.pending)
                    .firstOrNull
                    ?.key,
    );
  }

  final Map<OnboardingStep, OnboardingStatus> steps;

  /// Bước `pending` đầu tiên; `null` khi đã xử lý hết.
  final OnboardingStep? currentStep;

  int get handled =>
      steps.values.where((s) => s != OnboardingStatus.pending).length;

  @override
  List<Object?> get props => [steps, currentStep];
}
