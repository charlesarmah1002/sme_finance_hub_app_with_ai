import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sme_cashflow/providers/transactions_provider.dart';
import 'package:sme_cashflow/services/api_service.dart';

void main() {
  late HttpServer server;
  var transactionListCalls = 0;
  final sentTypes = <String>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    transactionListCalls = 0;
    sentTypes.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      if (request.uri.path == '/api/transactions/' && request.method == 'GET') {
        transactionListCalls++;
        _json(request.response, {'results': [_transactionJson]});
        return;
      }
      if (request.uri.path == '/api/accounts/') {
        _json(request.response, {'results': [{'id': 1, 'name': 'Main'}]});
        return;
      }
      if (request.uri.path == '/api/categories/') {
        _json(request.response, {'results': [{'id': 2, 'name': 'Office', 'type': 'expense'}]});
        return;
      }
      if (request.method == 'POST' || request.method == 'PUT') {
        final data = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
        sentTypes.add(data['type'] as String);
        _json(request.response, _transactionJson);
        return;
      }
      request.response..statusCode = HttpStatus.noContent..close();
    });
  });

  tearDown(() => server.close());

  test('loads, filters, and refreshes transactions after mutations', () async {
    final provider = TransactionsProvider(ApiService(baseUrl: 'http://127.0.0.1:${server.port}/api'));

    await provider.load();
    expect(provider.transactions.single.description, 'Office rental');
    provider.setFilter(TransactionFilter.expense);
    expect(provider.visibleTransactions, hasLength(1));
    expect(await provider.create(_payload), isTrue);
    expect(await provider.update(3, _payload), isTrue);
    expect(await provider.delete(3), isTrue);
    expect(transactionListCalls, 4);
    expect(sentTypes, ['expense', 'expense']);
  });
}

const _transactionJson = {
  'id': 3,
  'account': 1,
  'category': 2,
  'type': 'expense',
  'amount': '150.00',
  'description': 'Office rental',
  'date': '2026-09-04',
};

const _payload = {
  'account': 1,
  'category': 2,
  'type': 'expense',
  'amount': '150.00',
  'description': 'Office rental',
  'date': '2026-09-04',
};

void _json(HttpResponse response, Object body) {
  response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}