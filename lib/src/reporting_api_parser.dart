import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:quiver/collection.dart';

import 'data_model/insertion_order_daily_spend.dart';
import 'util.dart';

class ReportingQueryParser {
  /// Parse queryId from a json string.
  static String parseQueryIdFromJsonString(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    if (map.containsKey('error'))
      throw ParserResponseException(map['error']['message']);
    return map['queryId'];
  }

  /// Parse google storage download from a json string.
  static String parseDownloadPathFromJsonString(String jsonString) =>
      json.decode(jsonString)['metadata']
          ['googleCloudStoragePathForLatestReport'];

  /// Parses spending information from a json string.
  ///
  /// Returns a spendingMap that has insertion order as key and
  /// [InsertionOrderDailySpend] as value.
  static Multimap<String, InsertionOrderDailySpend> parseRevenueFromJsonString(
      String jsonString) {
    String report = json.decode(jsonString)['gapiRequest']['data']['body'];

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
    // and then put insertion order and the other entries into a map
    // by making ioID the key and InsertionOrderDailySpend the value.
    final revenueMap = Multimap<String, InsertionOrderDailySpend>();
    for (final row in reportTable) {
      // skip header
      if (row[0] == 'Insertion Order ID') continue;
      // stop if reach the empty string row
      if (row[0].isEmpty) return revenueMap;

      // row[0] stores io id, row[1] stores date, row[2] stores revenue,
      // and row[3] stores impression.
      revenueMap.add(
          row[0],
          (InsertionOrderDailySpendBuilder()
                ..date = Util.convertStringDateToDateTime(row[1])
                ..revenue = row[2]
                ..impression = row[3])
              .build());
    }

    return revenueMap;
  }
}
