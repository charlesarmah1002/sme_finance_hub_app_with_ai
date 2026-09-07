import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/feedback_widgets.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AccountsProvider provider;

  @override
  void initState() {
    super.initState();
    provider = AccountsProvider(context.read<AuthProvider>().apiService)
      ..load();
  }

  @override
  void dispose() {
    provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: provider, child: const _AccountsContent());
  }
}

class _AccountsContent extends StatelessWidget {
  const _AccountsContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountsProvider>();
    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(children: [
            Expanded(
                child: Text('Accounts',
                    style: Theme.of(context).textTheme.headlineSmall)),
            FilledButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Add account')),
          ]),
          const SizedBox(height: 16),
          _BalanceSummary(accounts: provider.accounts),
          const SizedBox(height: 16),
          if (provider.isLoading && provider.accounts.isEmpty)
            const LoadingWidget(),
          if (provider.errorMessage != null) ...[
            ErrorMessage(
                message: provider.errorMessage!, onRetry: provider.load),
          ],
          if (!provider.isLoading &&
              provider.errorMessage == null &&
              provider.accounts.isEmpty)
            const EmptyState(
                message: 'No accounts yet. Add your first account.'),
          for (final account in provider.accounts)
            _AccountTile(account: account),
        ],
      ),
    );
  }

  Future<void> _showForm(BuildContext context, [Account? account]) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _AccountForm(account: account));
    if (result == null || !context.mounted) return;
    final provider = context.read<AccountsProvider>();
    final success = account == null
        ? await provider.create(result)
        : await provider.update(account.id, result);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(account == null ? 'Account created.' : 'Account updated.')));
    }
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.accounts});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final total = accounts.fold<double>(
      0,
      (sum, account) => sum + (account.balance ?? 0),
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: const Text('Total balance'),
        subtitle: Text(
            '${accounts.length} account${accounts.length == 1 ? '' : 's'}'),
        trailing: Text(
          NumberFormat.currency(symbol: '').format(total),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final status = account.isActive == null
        ? null
        : account.isActive!
            ? 'Active'
            : 'Inactive';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: Text(account.name),
        subtitle: Text([
          if (account.type != null) account.type!,
          if (status != null) status
        ].join(' | ')),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(account.balance == null
              ? '--'
              : NumberFormat.currency(symbol: '').format(account.balance)),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final provider = context.read<AccountsProvider>();
              if (value == 'edit') await _edit(context, account);
              if (value == 'deactivate') {
                final success = await provider.deactivate(account.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Account deactivated successfully.')));
                }
              }
              if (value == 'delete') {
                final success = await provider.delete(account.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Account deleted successfully.')));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (account.isActive != false)
                const PopupMenuItem(
                    value: 'deactivate', child: Text('Deactivate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ]),
      ),
    );
  }

  Future<void> _edit(BuildContext context, Account account) async {
    final result = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => _AccountForm(account: account));
    if (result != null && context.mounted) {
      final success =
          await context.read<AccountsProvider>().update(account.id, result);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account updated successfully.')));
      }
    }
  }
}

class _AccountForm extends StatefulWidget {
  const _AccountForm({this.account});

  final Account? account;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  late final TextEditingController name =
      TextEditingController(text: widget.account?.name);
  late final TextEditingController type =
      TextEditingController(text: widget.account?.type);
  late final TextEditingController balance =
      TextEditingController(text: widget.account?.balance?.toString());
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    name.dispose();
    type.dispose();
    balance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.account == null ? 'Add account' : 'Edit account'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an account name'
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: type,
                decoration: const InputDecoration(labelText: 'Account type')),
            const SizedBox(height: 12),
            TextFormField(
                controller: balance,
                decoration: const InputDecoration(labelText: 'Balance'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    double.tryParse(value?.trim() ?? '') == null
                        ? 'Enter a valid balance'
                        : null),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': name.text.trim(),
      'type': type.text.trim(),
      if (widget.account == null)
        'opening_balance': double.parse(balance.text.trim()),
    });
  }
}
