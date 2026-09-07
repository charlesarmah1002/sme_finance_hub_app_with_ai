import 'package:flutter/foundation.dart';

import '../models/dashboard_summary.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this.apiService);

  final ApiService apiService;
  DashboardSummary? summary;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await apiService.dashboardSummary();
      summary = DashboardSummary.fromJson(response.data ?? const {});
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}