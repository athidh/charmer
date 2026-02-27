import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_route/main.dart';
import 'package:fresh_route/features/auth/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FreshRouteAIApp());
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
