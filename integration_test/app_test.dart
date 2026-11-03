import 'package:integration_test/integration_test.dart';

import '../test/app_test.dart' as flow;

/// The same sign-in → map → shares → sign-out flow as test/app_test.dart, but on a real emulator or phone.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  flow.main();
}
