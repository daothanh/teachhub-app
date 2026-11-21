// S5-FL-08: luồng A phần học phí. Cùng kịch bản với widget test
// (test/features/billing_flow/billing_flow_scenarios.dart), chạy trên máy:
//   flutter test integration_test/billing_flow_test.dart -d <máy> --flavor development
import 'package:integration_test/integration_test.dart';

import '../test/features/billing_flow/billing_flow_scenarios.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineBillingFlowTests();
}
