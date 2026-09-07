import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

enum TransactionFilter { all, income, expense }

class TransactionsProvider extends ChangeNotifier {
  TransactionsProvider(this.apiService);

  final ApiService apiService;
  List<CashflowTransaction> transactions = const [];
  List<Account> accounts = const [];
  List<TransactionCategory> categories = const [];
  TransactionFilter filter = TransactionFilter.all;
  bool isLoading = false;
  String? errorMessage;

  List<CashflowTransaction> get visibleTransactions {
    if (filter == TransactionFilter.all) return transactions;
    final type = filter == TransactionFilter.income ? TransactionType.income : TransactionType.expense;
    return transactions.where((item) => item.type == type).toList(growable: false);
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final responses = await Future.wait([apiService.transactions(), apiService.accounts(), apiService.categories()]);
      transactions = transactionsFromJson(responses[0].data);
      accounts = accountsFromJson(responses[1].data);
      categories = categoriesFromJson(responses[2].data);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final response = await apiService.categories();
      categories = categoriesFromJson(response.data);
      notifyListeners();
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    }
  }

  void setFilter(TransactionFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<bool> create(Map<String, dynamic> data) => _mutate(() => apiService.createTransaction(data));
  Future<bool> update(int id, Map<String, dynamic> data) => _mutate(() => apiService.updateTransaction(id, data));
  Future<bool> delete(int id) => _mutate(() => apiService.deleteTransaction(id));

  Future<bool> _mutate(Future<dynamic> Function() request) async {
    try {
      await request();
      await load();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }
}