import 'category.dart';

enum TransactionType { income, expense }

class CashflowTransaction {
  const CashflowTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.accountName,
    this.categoryName,
  });

  factory CashflowTransaction.fromJson(Map<String, dynamic> json) {
    final account = json['account'];
    final category = json['category'];
    final type = json['type']?.toString().toLowerCase() == 'income' ? TransactionType.income : TransactionType.expense;
    return CashflowTransaction(
      id: int.tryParse('${json['id']}') ?? 0,
      accountId: _id(account),
      categoryId: _id(category),
      type: type,
      amount: _number(json['amount']),
      description: (json['description'] ?? '').toString(),
      date: DateTime.tryParse('${json['date']}'),
      accountName: account is Map<String, dynamic> ? account['name']?.toString() : null,
      categoryName: category is Map<String, dynamic> ? category['name']?.toString() : null,
    );
  }

  final int id;
  final int accountId;
  final int categoryId;
  final TransactionType type;
  final double? amount;
  final String description;
  final DateTime? date;
  final String? accountName;
  final String? categoryName;

  static int _id(Object? value) => value is Map<String, dynamic> ? int.tryParse('${value['id']}') ?? 0 : int.tryParse('$value') ?? 0;
  static double? _number(Object? value) => value is num ? value.toDouble() : double.tryParse('$value');
}

List<CashflowTransaction> transactionsFromJson(Object? value) {
  final list = value is List ? value : value is Map<String, dynamic> ? value['results'] : null;
  if (list is! List) return const [];
  return list.whereType<Map<String, dynamic>>().map(CashflowTransaction.fromJson).toList(growable: false);
}

String transactionTypeValue(TransactionType type) => type == TransactionType.income ? 'income' : 'expense';

CategoryType categoryTypeFor(TransactionType type) => type == TransactionType.income ? CategoryType.income : CategoryType.expense;