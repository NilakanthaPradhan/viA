import 'package:flutter_test/flutter_test.dart';
import 'package:via_app/main.dart';

void main() {
  testWidgets('ViA app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ViAApp(showWelcome: false));
    expect(find.text('viA'), findsWidgets);
  });
}
