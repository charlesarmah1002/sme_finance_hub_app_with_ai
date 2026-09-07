// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sme_cashflow/app.dart';
import 'package:sme_cashflow/providers/auth_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  testWidgets('renders desktop navigation for authenticated users', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiService(), status: AuthStatus.authenticated),
        child: const CashflowApp(loadDashboard: false),
      ),
    );

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byTooltip('Logout'), findsOneWidget);
  });

  testWidgets('renders mobile primary navigation and overflow menu', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiService(), status: AuthStatus.authenticated),
        child: const CashflowApp(loadDashboard: false),
      ),
    );

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Accounts'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.byTooltip('More'), findsOneWidget);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pump();
    expect(find.text('Categories'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('More'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Settings').last);
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
