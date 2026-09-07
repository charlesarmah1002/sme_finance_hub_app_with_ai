import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/report_data.dart';
import '../providers/auth_provider.dart';
import '../providers/reports_provider.dart';
import '../widgets/feedback_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsProvider provider;

  @override
  void initState() {
    super.initState();
    provider = ReportsProvider(context.read<AuthProvider>().apiService)..load();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(value: provider, child: const _ReportsContent());
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    if (provider.isLoading && provider.cashflow == null) return const LoadingWidget();
    if (provider.errorMessage != null && provider.cashflow == null) {
      return ErrorMessage(message: provider.errorMessage!, onRetry: provider.load);
    }
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Cash Flow'), Tab(text: 'By Category'), Tab(text: 'By Account')]),
          Expanded(
            child: TabBarView(children: [
              _ReportView(title: 'Cash Flow', report: provider.cashflow),
              _ReportView(title: 'By Category', report: provider.byCategory),
              _ReportView(title: 'By Account', report: provider.byAccount),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.title, required this.report});

  final String title;
  final ReportData? report;

  @override
  Widget build(BuildContext context) {
    if (report == null || report!.isEmpty) return EmptyState(message: 'No $title data is available yet.');
    final scalarValues = report!.raw.entries.where((entry) => entry.value is! List && entry.value is! Map).toList();
    return RefreshIndicator(
      onRefresh: context.read<ReportsProvider>().load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (scalarValues.isNotEmpty) _ValueCards(values: scalarValues),
          if (report!.rows.isNotEmpty) ...[
            if (scalarValues.isNotEmpty) const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final row in report!.rows) _ReportRow(row: row),
          ],
          if (scalarValues.isEmpty && report!.rows.isEmpty)
            const Text('The API returned data that has no displayable fields.'),
        ],
      ),
    );
  }
}

class _ValueCards extends StatelessWidget {
  const _ValueCards({required this.values});

  final List<MapEntry<String, dynamic>> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final entry in values)
          SizedBox(
            width: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_label(entry.key)),
                  const SizedBox(height: 8),
                  Text('${entry.value}', style: Theme.of(context).textTheme.titleLarge),
                ]),
              ),
            ),
          ),
      ],
    );
  }

  String _label(String key) => key.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final entries = row.entries.where((entry) => entry.value is! Map && entry.value is! List).toList();
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final entry in entries) Text('${entry.key}: ${entry.value}')])));
  }
}

