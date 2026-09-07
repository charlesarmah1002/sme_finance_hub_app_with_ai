import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/models/category.dart';
import 'package:sme_cashflow/providers/categories_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;
  var listCalls = 0;
  final requestTypes = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    listCalls = 0;
    requestTypes.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/api/categories/' && request.method == 'GET') {
        listCalls++;
        _json(request.response, {'results': [_categoryJson]});
        return;
      }
      if (request.method == 'POST' || request.method == 'PUT') {
        final body = await utf8.decoder.bind(request).join();
        requestTypes.add((jsonDecode(body) as Map<String, dynamic>)['type'] as String);
        _json(request.response, _categoryJson);
        return;
      }
      if (request.method == 'DELETE') {
        request.response..statusCode = HttpStatus.noContent..close();
        return;
      }
      _json(request.response, _categoryJson);
    });
  });

  tearDown(() => server.close());

  test('loads and refreshes categories using API type values', () async {
    final provider = CategoriesProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));

    await provider.load();
    expect(provider.categories.single.type, CategoryType.income);
    expect(await provider.create(name: 'Sales', type: CategoryType.income), isTrue);
    expect(await provider.update(1, name: 'Supplies', type: CategoryType.expense), isTrue);
    expect(await provider.delete(1), isTrue);

    expect(requestTypes, ['income', 'expense']);
    expect(listCalls, 4);
    expect(provider.errorMessage, isNull);
  });
}

const _categoryJson = {'id': 1, 'name': 'Sales', 'type': 'income'};

void _json(HttpResponse response, Object body) {
  response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}