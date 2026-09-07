import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/models/dashboard_summary.dart';
import 'package:sme_cashflow/providers/dashboard_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  test('parses the supported dashboard summary fields', () {
    final summary = DashboardSummary.fromJson({
      'total_balance': '1200.50',
      'total_income': 2400,
      'total_expenses': 1199.5,
      'net_cash_flow': 1200.5,
      'recent_transactions': [
        {'description': 'Sale', 'amount': 100},
      ],
      'accounts': [
        {'name': 'Business account', 'balance': 1200.5},
      ],
    });

    expect(summary.totalBalance, 1200.5);
    expect(summary.totalIncome, 2400);
    expect(summary.recentTransactions.single['description'], 'Sale');
    expect(summary.accounts.single['name'], 'Business account');
  });

  test('provider exposes an empty API response as an empty summary', () async {
    SharedPreferences.setMockInitialValues({});
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({}))
        ..close();
    });
    addTearDown(server.close);

    final provider = DashboardProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));
    await provider.load();

    expect(provider.errorMessage, isNull);
    expect(provider.summary?.isEmpty, isTrue);
  });
}