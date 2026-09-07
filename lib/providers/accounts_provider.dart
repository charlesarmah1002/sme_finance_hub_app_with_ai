import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/api_service.dart';

class AccountsProvider extends ChangeNotifier {
  AccountsProvider(this.apiService);

  final ApiService apiService;
  List<Account> accounts = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await apiService.accounts();
      accounts = accountsFromJson(response.data);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> data) => _mutate(() => apiService.createAccount(data));

  Future<bool> update(int id, Map<String, dynamic> data) => _mutate(() => apiService.updateAccount(id, data));

  Future<bool> deactivate(int id) => _mutate(() => apiService.patchAccount(id, {'is_active': false}));

  Future<bool> delete(int id) => _mutate(() => apiService.deleteAccount(id));

  Future<bool> _mutate(Future<void> Function() request) async {
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