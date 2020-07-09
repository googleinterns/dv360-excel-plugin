import 'dart:convert';

class ReportingQueryParser {
  static const _emptyEntry = '';

  /// Parse queryId from a json string.
  static String parseQueryIdFromJsonString(String jsonString) =>
      json.decode(jsonString)['queryId'] ?? _emptyEntry;

  /// Parse google storage download from a json string.
  static String parseDownloadPathFromJsonString(String jsonString) =>
      (json.decode(jsonString)['metadata'] ??
          const {})['googleCloudStoragePathForLatestReport'] ??
      _emptyEntry;

  /// Parse revenue from a json string.
  static Map<String, String> parseRevenueFromString(String responseFull) {
    String responseBody =
        ((json.decode(responseFull)['gapiRequest'] ?? const {})['data'] ??
                const {})['body'] ??
            '';

    if (responseBody.isEmpty) return <String, String>{};

    // Extracts the substring after 'Revenue (USD)' and before 'Report Time',
    // and then split them on new line or comma.
    // The resulting list should look like [ioId, revenue, ioID, revenue...].
    final rangeStart =
        responseBody.indexOf('Revenue (USD)') + 'Revenue (USD)'.length + 1;
    final rangeEnd = responseBody.indexOf('Report Time');
    final stringList =
        responseBody.substring(rangeStart, rangeEnd).split(RegExp(r'[\n,]+'));

    // Make the list into a map by making ioID the key and revenue the value.
    final revenueMap = <String, String>{};
    for (var i = 0; i < stringList.length - 1; i = i + 2) {
      revenueMap[stringList[i]] = stringList[i + 1];
    }

    return revenueMap;
  }
}
