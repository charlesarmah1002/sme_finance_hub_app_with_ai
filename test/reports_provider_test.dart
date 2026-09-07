import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/providers/reports_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      final body = switch (request.uri.path) {
        '/api/reports/cashflow/' => {'total_income': '100', 'total_expenses': '40', 'series': [{'date': '2026-09-04', 'value': 60}]},
        '/api/reports/by-category/' => {'results': [{'category': 'Office', 'total': '40'}]},
        '/api/reports/by-account/' => {'results': [{'account': 'Main', 'total': '60'}]},
        _ => {},
      };
      _json(request.response, body);
    });
  });

  tearDown(() => server.close());

  test('loads actual data for each report tab', () async {
    final provider = ReportsProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));

    await provider.load();

    expect(provider.cashflow?.raw['total_income'], '100');
    expect(provider.cashflow?.rows.single['date'], '2026-09-04');
    expect(provider.byCategory?.rows.single['category'], 'Office');
    expect(provider.byAccount?.rows.single['account'], 'Main');
    expect(provider.errorMessage, isNull);
  });
}

void _json(HttpResponse response, Object body) {
  response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}