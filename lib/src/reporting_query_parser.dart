import 'dart:convert';

import 'package:csv/csv.dart';

class ReportingQueryParser {
  static const _emptyEntry = '';
  static const _emptyMap = <String, String>{};

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

  /// Parse revenue from a json string.
  static Map<String, String> parseRevenueFromJsonString(String jsonString) {
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
    // Header: Insertion Order ID(groupBy column), Revenue(metric column)
    //         insertion order id, revenue
    //         ....
    //         row with empty string
    //         Report parameters
    List<List<dynamic>> reportTable = const CsvToListConverter()
        .convert(report, eol: '\n', shouldParseNumbers: false);

    // Extracts the rows after header and before the empty row,
    // and then put insertion order and revenue entries into a map
    // by making ioID the key and revenue the value.
    final revenueMap = <String, String>{};
    for (final row in reportTable) {
      // skip header
      if (row[0] == 'Insertion Order ID') continue;
      // stop if reach the empty string row
      if (row[0].isEmpty) return revenueMap;

      revenueMap[row[0]] = row[1];
    }

    return revenueMap;
  }
}
