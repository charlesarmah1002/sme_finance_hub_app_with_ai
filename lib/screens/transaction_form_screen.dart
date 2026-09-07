import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/transactions_provider.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen(
      {super.key, required this.provider, this.transaction});

  final TransactionsProvider provider;
  final CashflowTransaction? transaction;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final formKey = GlobalKey<FormState>();
  late TransactionType type =
      widget.transaction?.type ?? TransactionType.expense;
  int? accountId;
  int? categoryId;
  late final amount =
      TextEditingController(text: widget.transaction?.amount?.toString());
  late final description =
      TextEditingController(text: widget.transaction?.description);
  DateTime? date;

  @override
  void initState() {
    super.initState();
    accountId = widget.transaction?.accountId;
    categoryId = widget.transaction?.categoryId;
    date = widget.transaction?.date;
    if (widget.provider.categories.isEmpty) {
      widget.provider.loadCategories().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories
        .where((item) => item.type == categoryTypeFor(type))
        .toList();
    if (!categories.any((item) => item.id == categoryId)) categoryId = null;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.transaction == null
              ? 'Add transaction'
              : 'Edit transaction')),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          DropdownButtonFormField<TransactionType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                    value: TransactionType.income, child: Text('Income')),
                DropdownMenuItem(
                    value: TransactionType.expense, child: Text('Expense'))
              ],
              onChanged: (value) => setState(() {
                    type = value!;
                    categoryId = null;
                  })),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
              initialValue: accountId,
              decoration: const InputDecoration(labelText: 'Account'),
              items: [
                for (final account in widget.provider.accounts)
                  DropdownMenuItem(value: account.id, child: Text(account.name))
              ],
              onChanged: (value) => setState(() => accountId = value),
              validator: (value) => value == null ? 'Select an account' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
              initialValue: categoryId,
              decoration: InputDecoration(
                  labelText: 'Category',
                  helperText: categories.isEmpty
                      ? 'No categories loaded. Refresh and try again.'
                      : null),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                      value: category.id, child: Text(category.name))
              ],
              onChanged: (value) => setState(() => categoryId = value),
              validator: (value) => value == null ? 'Select a category' : null),
          const SizedBox(height: 16),
          TextFormField(
              controller: amount,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                return parsed == null || parsed <= 0
                    ? 'Enter an amount greater than zero'
                    : null;
              }),
          const SizedBox(height: 16),
          TextFormField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 16),
          ListTile(
              title: Text(date == null
                  ? 'Date is required'
                  : DateFormat.yMMMd().format(date!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate),
          if (date == null)
            const Text('Select a date', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _submit, child: const Text('Save transaction')),
        ]),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: date ?? DateTime.now());
    if (picked != null) setState(() => date = picked);
  }

  void _submit() {
    if (!formKey.currentState!.validate() || date == null) return;
    Navigator.pop(context, {
      'account': accountId,
      'category': categoryId,
      'type': transactionTypeValue(type),
      'amount': double.parse(amount.text.trim()).toStringAsFixed(2),
      'description': description.text.trim(),
      'date': DateFormat('yyyy-MM-dd').format(date!),
    });
  }
}
