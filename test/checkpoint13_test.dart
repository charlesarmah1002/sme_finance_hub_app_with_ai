import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/app.dart';
import 'package:sme_cashflow/models/transaction.dart';
import 'package:sme_cashflow/providers/auth_provider.dart';
import 'package:sme_cashflow/providers/transactions_provider.dart';
import 'package:sme_cashflow/screens/login_screen.dart';
import 'package:sme_cashflow/screens/register_screen.dart';
import 'package:sme_cashflow/screens/transaction_form_screen.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login form validates required fields', (WidgetTester tester) async {
    await tester.pumpWidget(_withAuth(const LoginScreen()));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('registration form validates required fields', (WidgetTester tester) async {
    await tester.pumpWidget(_withAuth(const RegisterScreen()));

    await tester.tap(find.text('Register'));
    await tester.pump();

    expect(find.text('This field is required'), findsNWidgets(2));
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('transaction form rejects a non-positive amount', (WidgetTester tester) async {
    final provider = TransactionsProvider(ApiService());
    await tester.pumpWidget(MaterialApp(home: TransactionFormScreen(provider: provider)));

    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '0');
    await tester.tap(find.text('Save transaction'));
    await tester.pump();

    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
  });

  testWidgets('unauthenticated application shows Login', (WidgetTester tester) async {
    await tester.pumpWidget(_withAuth(const CashflowApp(loadDashboard: false), status: AuthStatus.unauthenticated));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  test('transaction JSON parsing maps API values', () {
    final transaction = CashflowTransaction.fromJson({
      'id': 7,
      'account': {'id': 1, 'name': 'Main account'},
      'category': {'id': 2, 'name': 'Office'},
      'type': 'expense',
      'amount': '150.00',
      'description': 'Office rental',
      'date': '2026-09-04',
    });

    expect(transaction.id, 7);
    expect(transaction.accountId, 1);
    expect(transaction.categoryId, 2);
    expect(transaction.type, TransactionType.expense);
    expect(transaction.amount, 150);
    expect(transaction.date, DateTime(2026, 9, 4));
  });
}

Widget _withAuth(Widget child, {AuthStatus status = AuthStatus.unauthenticated}) {
  return ChangeNotifierProvider(
    create: (_) => AuthProvider(ApiService(), status: status),
    child: MaterialApp(home: child),
  );
}