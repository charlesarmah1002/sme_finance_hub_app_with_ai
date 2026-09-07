class ReportData {
  const ReportData({required this.raw, required this.rows});

  factory ReportData.fromJson(Object? value) {
    if (value is List) {
      return ReportData(raw: const {}, rows: _mapRows(value));
    }
    if (value is Map<String, dynamic>) {
      final rows = value['results'] ?? value['data'] ?? value['items'] ?? value['series'];
      return ReportData(raw: value, rows: rows is List ? _mapRows(rows) : const []);
    }
    return const ReportData(raw: {}, rows: []);
  }

  final Map<String, dynamic> raw;
  final List<Map<String, dynamic>> rows;

  bool get isEmpty => raw.isEmpty && rows.isEmpty;

  static List<Map<String, dynamic>> _mapRows(List<dynamic> values) {
    return values.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}