import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sme_cashflow/app.dart';
import 'package:sme_cashflow/models/account.dart';
import 'package:sme_cashflow/models/category.dart';
import 'package:sme_cashflow/providers/auth_provider.dart';
import 'package:sme_cashflow/providers/transactions_provider.dart';
import 'package:sme_cashflow/screens/transaction_form_screen.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  testWidgets('authenticated shell fits supported viewport widths', (WidgetTester tester) async {
    for (final width in [360.0, 390.0, 430.0, 768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ApiService(), status: AuthStatus.authenticated),
          child: const CashflowApp(loadDashboard: false),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'viewport width $width');
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('transaction form fits a phone viewport', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = TransactionsProvider(ApiService())
      ..accounts = const [Account(id: 1, name: 'Main account')]
      ..categories = const [TransactionCategory(id: 2, name: 'Office', type: CategoryType.expense)];

    await tester.pumpWidget(MaterialApp(home: TransactionFormScreen(provider: provider)));
    await tester.pump();

    expect(find.text('Save transaction'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}