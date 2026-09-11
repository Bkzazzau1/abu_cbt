import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:k_slas_cbt/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots into workstation registration flow', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const CenterExamApp());
    await tester.pumpAndSettle();

    expect(find.text('Workstation Registration'), findsOneWidget);
  });
}
