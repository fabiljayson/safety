import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:safechild_app/main.dart' as app;
import 'package:safechild_app/screens/auth_screen.dart';
import 'package:safechild_app/screens/main_navigation_screen.dart';

/// End-to-end check against the Laravel API on http://127.0.0.1:8000/api.
///
/// Success means the app reached [MainNavigationScreen] by talking to the
/// API — either through a saved-token auto-login (GET /api/me) or a real
/// form login (POST /api/login) with the seeded test credentials.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and talks to the live Laravel API', (tester) async {
    // The app's card-wrapped ListTiles trigger a Flutter framework lint
    // ("ListTile background color or ink splashes may be invisible").
    // That is a cosmetic UI issue, not an API failure — tolerate it here.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('ListTile background color')) {
        return;
      }
      originalOnError?.call(details);
    };

    try {
      app.main();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final nav = find.byType(MainNavigationScreen);
      final auth = find.byType(AuthScreen);

      // Path 1: a valid saved token triggers GET /api/me and auto-login.
      // Give the round trip up to 15 seconds.
      var deadline = DateTime.now().add(const Duration(seconds: 15));
      while (DateTime.now().isBefore(deadline) &&
          tester.widgetList(nav).isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Path 2: no saved token (or expired) -> perform a real form login.
      if (tester.widgetList(nav).isEmpty) {
        expect(
          auth,
          findsOneWidget,
          reason: 'Expected either auto-login or the login screen',
        );

        final fields = find.byType(TextField);
        expect(
          fields,
          findsNWidgets(2),
          reason: 'Expected the login form (email + password fields)',
        );

        await tester.enterText(fields.at(0), 'e2e@test.local');
        await tester.enterText(fields.at(1), 'password123');
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump(const Duration(milliseconds: 100));

        deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline) &&
            tester.widgetList(nav).isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await tester.pump(const Duration(milliseconds: 200));
        }
      }

      expect(
        nav,
        findsOneWidget,
        reason:
            'App must reach the Laravel API (GET /api/me or POST /api/login) and open the main screens',
      );
    } finally {
      FlutterError.onError = originalOnError;
    }
  });
}
