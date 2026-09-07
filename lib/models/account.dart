class Account {
  const Account({required this.id, required this.name, this.type, this.balance, this.isActive});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: _int(json['id']),
      name: (json['name'] ?? 'Unnamed account').toString(),
      type: (json['account_type'] ?? json['type'])?.toString(),
      balance: _number(json['balance']),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : null,
    );
  }

  final int id;
  final String name;
  final String? type;
  final double? balance;
  final bool? isActive;

  static int _int(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

List<Account> accountsFromJson(Object? value) {
  final list = value is List ? value : value is Map<String, dynamic> ? value['results'] : null;
  if (list is! List) return const [];
  return list.whereType<Map<String, dynamic>>().map(Account.fromJson).toList(growable: false);
}