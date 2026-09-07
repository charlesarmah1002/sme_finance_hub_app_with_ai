import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

class TransactionDetails extends StatelessWidget {
  const TransactionDetails({super.key, required this.transaction});

  final CashflowTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction details')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(transaction.description.isEmpty ? 'Untitled transaction' : transaction.description, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        _Detail(label: 'Amount', value: transaction.amount == null ? '--' : NumberFormat.currency(symbol: '').format(transaction.amount)),
        _Detail(label: 'Type', value: transactionTypeValue(transaction.type)),
        _Detail(label: 'Category', value: transaction.categoryName ?? 'Category #${transaction.categoryId}'),
        _Detail(label: 'Account', value: transaction.accountName ?? 'Account #${transaction.accountId}'),
        _Detail(label: 'Date', value: transaction.date == null ? '--' : DateFormat.yMMMMd().format(transaction.date!)),
      ]),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(title: Text(label), trailing: Text(value));
}