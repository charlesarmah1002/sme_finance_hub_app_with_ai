import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transactions_provider.dart';
import 'transaction_details.dart';
import 'transaction_form_screen.dart';
import '../widgets/feedback_widgets.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TransactionsProvider provider;

  @override
  void initState() {
    super.initState();
    provider = TransactionsProvider(context.read<AuthProvider>().apiService)..load();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(value: provider, child: const _TransactionsContent());
}

class _TransactionsContent extends StatelessWidget {
  const _TransactionsContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(children: [
            Expanded(child: Text('Transactions', style: Theme.of(context).textTheme.headlineSmall)),
            FilledButton.icon(onPressed: () => _openForm(context), icon: const Icon(Icons.add), label: const Text('Add transaction')),
          ]),
          const SizedBox(height: 16),
          SegmentedButton<TransactionFilter>(
            segments: const [
              ButtonSegment(value: TransactionFilter.all, label: Text('All')),
              ButtonSegment(value: TransactionFilter.income, label: Text('Income')),
              ButtonSegment(value: TransactionFilter.expense, label: Text('Expense')),
            ],
            selected: {provider.filter},
            onSelectionChanged: (selection) => provider.setFilter(selection.first),
          ),
          const SizedBox(height: 16),
          if (provider.isLoading && provider.transactions.isEmpty) const LoadingWidget(),
          if (provider.errorMessage != null) ...[
            ErrorMessage(message: provider.errorMessage!, onRetry: provider.load),
          ],
          if (!provider.isLoading && provider.errorMessage == null && provider.visibleTransactions.isEmpty)
            const EmptyState(message: 'No transactions found.'),
          for (final item in provider.visibleTransactions) _TransactionTile(item: item),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [CashflowTransaction? transaction]) async {
    final data = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormScreen(provider: context.read<TransactionsProvider>(), transaction: transaction)),
    );
    if (data == null || !context.mounted) return;
    final provider = context.read<TransactionsProvider>();
    final success = transaction == null ? await provider.create(data) : await provider.update(transaction.id, data);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? (transaction == null ? 'Transaction created.' : 'Transaction updated.') : provider.errorMessage ?? 'Request failed.')));
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final CashflowTransaction item;

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == TransactionType.income;
    final color = isIncome ? Colors.green : Theme.of(context).colorScheme.error;
    final amount = item.amount == null ? '--' : '${isIncome ? '+' : '-'}${NumberFormat.currency(symbol: '').format(item.amount)}';
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionDetails(transaction: item))),
        leading: CircleAvatar(backgroundColor: color.withAlpha(30), child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: color)),
        title: Text(item.description.isEmpty ? 'Untitled transaction' : item.description),
        subtitle: Text([item.categoryName ?? 'Category #${item.categoryId}', item.accountName ?? 'Account #${item.accountId}', if (item.date != null) DateFormat.yMMMd().format(item.date!)].join(' | ')),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                if (context.mounted) await _edit(context);
              } else if (value == 'delete') {
                final success = await context.read<TransactionsProvider>().delete(item.id);
                if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
          ),
        ]),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final data = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(provider: context.read<TransactionsProvider>(), transaction: item)));
    if (data != null && context.mounted) {
      final success = await context.read<TransactionsProvider>().update(item.id, data);
      if (success && context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction updated.')));
    }
  }
}