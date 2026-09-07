enum CategoryType { income, expense }

class TransactionCategory {
  const TransactionCategory({required this.id, required this.name, required this.type});

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString().toLowerCase();
    return TransactionCategory(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? 'Unnamed category').toString(),
      type: type == 'income' ? CategoryType.income : CategoryType.expense,
    );
  }

  final int id;
  final String name;
  final CategoryType type;
}

List<TransactionCategory> categoriesFromJson(Object? value) {
  final list = value is List
      ? value
      : value is Map<String, dynamic>
          ? value['results'] ?? value['data'] ?? value['categories']
          : null;
  if (list is! List) return const [];
  return list.whereType<Map<String, dynamic>>().map(TransactionCategory.fromJson).toList(growable: false);
}