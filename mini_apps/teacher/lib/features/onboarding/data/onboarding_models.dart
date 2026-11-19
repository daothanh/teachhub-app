import 'package:equatable/equatable.dart';

/// Khóa bước theo thứ tự của hợp đồng (`Onboarding.steps[].step`).
enum OnboardingStep {
  createClass('create_class'),
  addStudents('add_students'),
  setSchedule('set_schedule'),
  payoutAccount('payout_account'),
  complianceChecklist('compliance_checklist');

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

  static OnboardingStatus fromWire(String wire) =>
      values.firstWhere((s) => s.name == wire);
}

class Onboarding extends Equatable {
  const Onboarding({required this.steps, required this.currentStep});

  factory Onboarding.fromJson(Map<String, dynamic> json) => Onboarding(
    steps: {
      for (final raw in json['steps'] as List)
        OnboardingStep.fromWire((raw as Map)['step'] as String)!:
            OnboardingStatus.fromWire(raw['status'] as String),
    },
    currentStep: OnboardingStep.fromWire(json['currentStep'] as String?),
  );

  final Map<OnboardingStep, OnboardingStatus> steps;

  /// Bước `pending` đầu tiên; `null` khi đã xử lý hết.
  final OnboardingStep? currentStep;

  int get handled =>
      steps.values.where((s) => s != OnboardingStatus.pending).length;

  @override
  List<Object?> get props => [steps, currentStep];
}
