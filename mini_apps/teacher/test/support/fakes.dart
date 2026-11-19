import 'package:teacher/features/students/data/contacts_service.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/onboarding/data/onboarding_repository.dart';
import 'package:teacher/features/students/data/student_models.dart';
import 'package:teacher/features/students/data/student_repository.dart';

/// Trả lần lượt từng kết quả đã xếp hàng (giá trị hoặc lỗi để ném).
class FakeStudentRepository implements StudentRepository {
  FakeStudentRepository(this._results);
  final List<Object> _results;
  final calls = <({StudentDraft draft, bool confirmNew, String key})>[];

  @override
  Future<Student> create(
    StudentDraft draft, {
    required String idempotencyKey,
    bool confirmNew = false,
  }) async {
    calls.add((draft: draft, confirmNew: confirmNew, key: idempotencyKey));
    final r = _results.removeAt(0);
    if (r is Student) return r;
    throw r;
  }
}

Onboarding onboardingOf(Map<OnboardingStep, OnboardingStatus> overrides) {
  final steps = {
    for (final s in OnboardingStep.values) s: OnboardingStatus.pending,
    ...overrides,
  };
  return Onboarding(
    steps: steps,
    currentStep: steps.entries
        .where((e) => e.value == OnboardingStatus.pending)
        .firstOrNull
        ?.key,
  );
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository(this._state, {this.getError, this.patchError});
  Onboarding _state;
  final Object? getError;
  Object? patchError;
  final patches = <(OnboardingStep, OnboardingStatus)>[];

  @override
  Future<Onboarding> get() async {
    if (getError != null) throw getError!;
    return _state;
  }

  @override
  Future<Onboarding> patchStep(
    OnboardingStep step,
    OnboardingStatus status,
  ) async {
    patches.add((step, status));
    if (patchError != null) throw patchError!;
    return _state = onboardingOf({
      for (final e in _state.steps.entries) e.key: e.value,
      step: status,
    });
  }
}

class FakeContactsService implements ContactsService {
  FakeContactsService({
    this.access = ContactsAccess.granted,
    this.contacts = const [],
  });
  ContactsAccess access;
  final List<PickableContact> contacts;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<ContactsAccess> requestAccess() async {
    requests++;
    return access;
  }

  @override
  Future<List<PickableContact>> load() async => contacts;

  @override
  Future<void> openSettings() async => settingsOpened++;
}
