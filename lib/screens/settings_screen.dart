import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser ?? const <String, dynamic>{};

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _InfoTile(label: 'Name', value: _profileValue(user, 'name')),
              _InfoTile(label: 'Email', value: _profileValue(user, 'email')),
              _InfoTile(label: 'Business name', value: _businessName(user)),
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
    final direct =
        _profileValue(user, 'business_name', alternateKey: 'businessName');
    if (direct != 'Not provided') return direct;
    final business = user['business'];
    if (business is Map<String, dynamic>) {
      return _value(business['name']);
    }
    final nestedUser = user['user'];
    if (nestedUser is Map<String, dynamic>) {
      final nestedBusiness = nestedUser['business'];
      if (nestedBusiness is Map<String, dynamic>) {
        return _value(nestedBusiness['name']);
      }
    }
    return 'Not provided';
  }

  String _profileValue(Map<String, dynamic> user, String key,
      {String? alternateKey}) {
    final values = [
      user[key],
      if (alternateKey != null) user[alternateKey],
      if (user['user'] is Map<String, dynamic>)
        (user['user'] as Map<String, dynamic>)[key],
      if (alternateKey != null && user['user'] is Map<String, dynamic>)
        (user['user'] as Map<String, dynamic>)[alternateKey],
    ];
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
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
