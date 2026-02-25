import 'package:flutter_test/flutter_test.dart';
import 'package:anima/src/rust/frb_generated.dart';
import 'package:anima/src/rust/api/simple.dart' as rust_simple;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    final greeting = rust_simple.greet(name: 'Tom');
    expect(greeting, 'Hello, Tom!');
  });
}
