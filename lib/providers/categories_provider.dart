import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../services/api_service.dart';

class CategoriesProvider extends ChangeNotifier {
  CategoriesProvider(this.apiService);

  final ApiService apiService;
  List<TransactionCategory> categories = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await apiService.categories();
      categories = categoriesFromJson(response.data);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({required String name, required CategoryType type}) {
    return _mutate(() => apiService.createCategory({'name': name, 'type': type.name}));
  }

  Future<bool> update(int id, {required String name, required CategoryType type}) {
    return _mutate(() => apiService.updateCategory(id, {'name': name, 'type': type.name}));
  }

  Future<bool> delete(int id) => _mutate(() => apiService.deleteCategory(id));

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