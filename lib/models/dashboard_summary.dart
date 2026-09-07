class DashboardSummary {
  const DashboardSummary({
    this.totalBalance,
    this.totalIncome,
    this.totalExpenses,
    this.netCashFlow,
    this.recentTransactions = const [],
    this.accounts = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final data = summary is Map<String, dynamic> ? summary : json;
    return DashboardSummary(
      totalBalance: _number(data['total_balance']),
      totalIncome: _number(data['total_income']),
      totalExpenses: _number(data['total_expenses']),
      netCashFlow: _number(data['net_cash_flow']),
      recentTransactions: _list(data['recent_transactions']),
      accounts: _list(data['accounts']),
    );
  }

  final double? totalBalance;
  final double? totalIncome;
  final double? totalExpenses;
  final double? netCashFlow;
  final List<Map<String, dynamic>> recentTransactions;
  final List<Map<String, dynamic>> accounts;

  bool get isEmpty =>
      totalBalance == null &&
      totalIncome == null &&
      totalExpenses == null &&
      netCashFlow == null &&
      recentTransactions.isEmpty &&
      accounts.isEmpty;

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}