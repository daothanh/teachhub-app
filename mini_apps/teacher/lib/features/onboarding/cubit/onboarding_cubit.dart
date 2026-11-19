import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:teachhub_shared/teachhub_shared.dart';

import '../data/onboarding_models.dart';
import '../data/onboarding_repository.dart';

enum OnboardingLoad { loading, ready, failure }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.load = OnboardingLoad.loading,
    this.onboarding,
    this.saving = false,
    this.error,
  });

  final OnboardingLoad load;
  final Onboarding? onboarding;
  final bool saving;

  /// Lỗi của lần lưu bước gần nhất (màn hiện SnackBar rồi bỏ qua).
  final ApiException? error;

  @override
  List<Object?> get props => [load, onboarding, saving, error];
}

/// Tiến độ 5 bước (US-0.2). Server là nguồn sự thật: mở lại app thì [load]
/// trả `currentStep` là bước dở.
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repo) : super(const OnboardingState());

  final OnboardingRepository _repo;

  Future<void> load() async {
    emit(const OnboardingState());
    try {
      emit(
        OnboardingState(
          load: OnboardingLoad.ready,
          onboarding: await _repo.get(),
        ),
      );
    } on ApiException catch (e) {
      emit(OnboardingState(load: OnboardingLoad.failure, error: e));
    }
  }

  Future<void> complete(OnboardingStep step) =>
      _patch(step, OnboardingStatus.done);

  Future<void> skip(OnboardingStep step) =>
      _patch(step, OnboardingStatus.skipped);

  Future<void> _patch(OnboardingStep step, OnboardingStatus status) async {
    final current = state.onboarding;
    if (state.saving || current == null) return;
    emit(
      OnboardingState(
        load: OnboardingLoad.ready,
        onboarding: current,
        saving: true,
      ),
    );
    try {
      final next = await _repo.patchStep(step, status);
      emit(OnboardingState(load: OnboardingLoad.ready, onboarding: next));
    } on ApiException catch (e) {
      emit(
        OnboardingState(
          load: OnboardingLoad.ready,
          onboarding: current,
          error: e,
        ),
      );
    }
  }
}
