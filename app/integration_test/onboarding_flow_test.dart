// S2-FL-06: luồng B onboarding. Cùng kịch bản với widget test
// (test/features/onboarding_flow/onboarding_flow_scenarios.dart), chạy trên máy:
//   flutter test integration_test/onboarding_flow_test.dart -d <máy> --flavor development
import 'package:integration_test/integration_test.dart';

import '../test/features/onboarding_flow/onboarding_flow_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineOnboardingFlowTests();
}
