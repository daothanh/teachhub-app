// S1-FL-04: 3 nhánh của splash/guard. Cùng kịch bản với widget test
// (test/features/splash/splash_guard_scenarios.dart), chạy trên máy:
//   flutter test integration_test/splash_guard_test.dart -d <máy> --flavor development
import 'package:integration_test/integration_test.dart';

import '../test/features/splash/splash_guard_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineSplashGuardTests();
}
