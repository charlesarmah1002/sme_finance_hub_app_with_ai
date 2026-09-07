import 'package:flutter/foundation.dart';

import '../models/report_data.dart';
import '../services/api_service.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this.apiService);

  final ApiService apiService;
  ReportData? cashflow;
  ReportData? byCategory;
  ReportData? byAccount;
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final responses = await Future.wait([
        apiService.cashflowReport(),
        apiService.categoryReport(),
        apiService.accountReport(),
      ]);
      cashflow = ReportData.fromJson(responses[0].data);
      byCategory = ReportData.fromJson(responses[1].data);
      byAccount = ReportData.fromJson(responses[2].data);
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}