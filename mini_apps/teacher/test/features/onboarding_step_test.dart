import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:tasco_storage/tasco_storage.dart';
import 'package:teacher/features/onboarding/data/onboarding_draft.dart';
import 'package:teacher/features/onboarding/data/onboarding_models.dart';
import 'package:teacher/features/onboarding/data/onboarding_repository.dart';
import 'package:teacher/features/onboarding/pages/onboarding_page.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('AC-3: mở thẳng một bước đã bỏ qua; xong thì quay về màn trước', (
    tester,
  ) async {
    final repo = FakeOnboardingRepository(
      onboardingOf({
        OnboardingStep.createClass: OnboardingStatus.done,
        OnboardingStep.addStudents: OnboardingStatus.done,
        OnboardingStep.setSchedule: OnboardingStatus.skipped,
      }),
    );
    GetIt.I.registerSingleton<OnboardingRepository>(repo);
    GetIt.I.registerSingleton<OnboardingDraftStore>(
      OnboardingDraftStore(InMemoryKeyValueStore()),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => TextButton(
            onPressed: () => context.push('/step'),
            child: const Text('mở'),
          ),
        ),
        GoRoute(
          path: '/step',
          builder: (_, _) =>
              const OnboardingPage(initialStep: OnboardingStep.setSchedule),
        ),
      ],
    );
    await pumpRouter(tester, router);
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();

    // Bước dở là "payoutAccount" (đầu tiên còn pending) nhưng màn mở bước 3.
    expect(find.text('Bước 3/5'), findsOneWidget);
    expect(find.text('Đặt lịch học'), findsOneWidget);

    await tester.tap(find.text('Để sau'));
    await tester.pumpAndSettle();
    expect(repo.patches, [
      (OnboardingStep.setSchedule, OnboardingStatus.skipped),
    ]);
    expect(find.text('mở'), findsOneWidget);
  });
}
