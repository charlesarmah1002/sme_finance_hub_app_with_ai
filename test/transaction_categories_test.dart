import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/models/category.dart';
import 'package:sme_cashflow/providers/transactions_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  test('reads categories from the local API endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    var requestedPath = '';
    server.listen((request) {
      requestedPath = request.uri.path;
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'data': [
          {'id': 2, 'name': 'Office', 'type': 'expense'},
        ]}))
        ..close();
    });

    final provider = TransactionsProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));
    await provider.loadCategories();

    expect(requestedPath, '/api/categories/');
    expect(provider.categories.single.name, 'Office');
    expect(provider.categories.single.type, CategoryType.expense);
    expect(provider.errorMessage, isNull);
  });
}
