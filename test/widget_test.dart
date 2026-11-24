import 'package:flutter_test/flutter_test.dart';
import 'package:fpn_berkah_abadi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the login dialog after activation', (tester) async {
    SharedPreferences.setMockInitialValues({'is_activated': true});

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('LOGIN APLIKASI'), findsOneWidget);
  });
}
