import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_summary.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/feedback_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.loadOnStart = true});

  final bool loadOnStart;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardProvider provider;

  @override
  void initState() {
    super.initState();
    provider = DashboardProvider(context.read<AuthProvider>().apiService);
    if (widget.loadOnStart) provider.load();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    if (provider.isLoading && provider.summary == null) {
      return const LoadingWidget();
    }
    if (provider.errorMessage != null && provider.summary == null) {
      return ErrorMessage(
        message: provider.errorMessage!,
        onRetry: provider.load,
      );
    }

    final summary = provider.summary;
    if (summary == null || summary.isEmpty) {
      return EmptyState(message: 'No dashboard data is available yet.', action: provider.load, actionLabel: 'Retry');
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _SummaryGrid(summary: summary),
          if (summary.recentTransactions.isNotEmpty) ...[
            const SizedBox(height: 32),
            _JsonSection(title: 'Recent Transactions', items: summary.recentTransactions),
          ],
          if (summary.accounts.isNotEmpty) ...[
            const SizedBox(height: 32),
            _JsonSection(title: 'Accounts', items: summary.accounts),
          ],
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final values = [
      ('Balance', summary.totalBalance, Icons.account_balance_wallet_outlined),
      ('Income', summary.totalIncome, Icons.trending_up),
      ('Expenses', summary.totalExpenses, Icons.trending_down),
      ('Net Cash Flow', summary.netCashFlow, Icons.swap_vert),
    ];
    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final value in values)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(value.$3, color: Theme.of(context).colorScheme.primary),
                  Text(value.$1),
                  Text(value.$2 == null ? '--' : NumberFormat.currency(symbol: '').format(value.$2), style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _JsonSection extends StatelessWidget {
  const _JsonSection({required this.title, required this.items});

  final String title;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final item in items.take(5))
          Card(
            child: ListTile(
              title: Text(_title(item)),
              subtitle: Text(_subtitle(item)),
            ),
          ),
      ],
    );
  }

  String _title(Map<String, dynamic> item) {
    return (item['name'] ?? item['description'] ?? item['title'] ?? 'Item').toString();
  }

  String _subtitle(Map<String, dynamic> item) {
    final amount = item['amount'] ?? item['balance'] ?? item['date'];
    return amount?.toString() ?? 'Details unavailable';
  }
}

