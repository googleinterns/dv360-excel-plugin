import 'dart:convert';

import 'package:csv/csv.dart';

import 'util.dart';

class ReportingQueryParser {
  static const _emptyEntry = '';
  static const _emptyMap = <String, List<InsertionOrderDailySpend>>{};

  /// Parse queryId from a json string.
  static String parseQueryIdFromJsonString(String jsonString) {
    if (jsonString == null || jsonString.isEmpty || jsonString == 'null') {
      return _emptyEntry;
    }
    return json.decode(jsonString)['queryId'] ?? _emptyEntry;
  }

  /// Parse google storage download from a json string.
  static String parseDownloadPathFromJsonString(String jsonString) {
    if (jsonString == null || jsonString.isEmpty || jsonString == 'null') {
      return _emptyEntry;
    }

    Map<String, dynamic> responseMap = json.decode(jsonString);
    if (!responseMap.containsKey('metadata') ||
        !responseMap['metadata']
            .containsKey('googleCloudStoragePathForLatestReport')) {
      return _emptyEntry;
    }

    return responseMap['metadata']['googleCloudStoragePathForLatestReport'];
  }

  /// Parses spending information from a json string.
  ///
  /// Returns a spendingMap that has insertion order as key and
  /// [InsertionOrderDailySpend] as value.
  static Map<String, List<InsertionOrderDailySpend>> parseRevenueFromJsonString(
      String jsonString) {
    if (jsonString == null || jsonString.isEmpty || jsonString == 'null') {
      return _emptyMap;
    }

    Map<String, dynamic> responseMap = json.decode(jsonString);
    if (!responseMap.containsKey('gapiRequest') ||
        !responseMap['gapiRequest'].containsKey('data') ||
        !responseMap['gapiRequest']['data'].containsKey('body')) {
      return _emptyMap;
    }

    String report = responseMap['gapiRequest']['data']['body'];

    // Based on the query constructed by [QueryService._execReportingCreateQuery],
    // the report has the following format:
    //
    // Header: Insertion Order ID,    Date,       Revenue,      Impression
    // Body:   io id,                 date,       revenue,      impression
    //         ....
    //         empty,                 empty,      revenue sum,  impression sum
    //         row with empty string
    //         Report parameters
    List<List<dynamic>> reportTable = const CsvToListConverter()
        .convert(report, eol: '\n', shouldParseNumbers: false);

    // Extracts the rows after header and before the empty row,
    // and then put insertion order and revenue entries into a map
    // by making ioID the key and revenue the value.
    final revenueMap = <String, List<InsertionOrderDailySpend>>{};
    for (final row in reportTable) {
      // skip header
      if (row[0] == 'Insertion Order ID') continue;
      // stop if reach the empty string row
      if (row[0].isEmpty) return revenueMap;

      final insertionOrderId = row[0];
      final date = Util.convertStringDateToDateTime(row[1]);
      final revenue = row[2];
      final impression = row[3];

      final dailySpendList = revenueMap.putIfAbsent(
          insertionOrderId, () => <InsertionOrderDailySpend>[]);
      dailySpendList.add(InsertionOrderDailySpend(date, revenue, impression));
      revenueMap[insertionOrderId] = dailySpendList;
    }

    return revenueMap;
  }
}

class InsertionOrderDailySpend {
  final DateTime _date;
  final String _revenue;
  final String _impression;

  DateTime get date => _date;
  String get revenue => _revenue;
  String get impression => _impression;

  InsertionOrderDailySpend(this._date, this._revenue, this._impression);
}
