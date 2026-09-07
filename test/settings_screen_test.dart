import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/providers/auth_provider.dart';
import 'package:sme_cashflow/screens/settings_screen.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  testWidgets('displays current user information and logs out', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      ApiService.accessTokenKey: 'access-token',
      ApiService.refreshTokenKey: 'refresh-token',
    });
    final auth = AuthProvider(ApiService(), status: AuthStatus.authenticated)
      ..currentUser = {
        'name': 'Alex Owner',
        'email': 'alex@example.com',
        'business': {'name': 'Example Ltd'},
      };

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Alex Owner'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Example Ltd'), findsOneWidget);

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(await auth.apiService.getAccessToken(), isNull);
    expect(await auth.apiService.getRefreshToken(), isNull);
  });
}