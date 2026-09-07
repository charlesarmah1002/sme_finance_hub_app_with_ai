import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser ?? const <String, dynamic>{};
    final businessName = _businessName(user);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _InfoTile(label: 'Name', value: _value(user['name'])),
              _InfoTile(label: 'Email', value: _value(user['email'])),
              _InfoTile(label: 'Business name', value: businessName),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  String _businessName(Map<String, dynamic> user) {
    final direct = user['business_name'] ?? user['businessName'];
    if (direct != null) return direct.toString();
    final business = user['business'];
    if (business is Map<String, dynamic>) return _value(business['name']);
    return 'Not provided';
  }

  String _value(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not provided' : text;
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}