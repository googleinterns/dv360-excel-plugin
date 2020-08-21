import 'dart:async';

import 'package:csv/csv.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/doubleclickbidmanager/v1_1.dart';
import 'package:http/http.dart';

/// A class to get the metric values of DV360 line items.
class ReportingClient {
  /// A map from the metric name to the name of the column name in the report.
  ///
  /// See: https://developers.google.com/bid-manager/v1.1/filters-metrics
  static const metricToReportColumnName = {
    'METRIC_REVENUE_ECPM_ADVERTISER': 'Revenue eCPM (Adv Currency)',
  };

  /// The Reporting API.
  final DoubleclickbidmanagerApi _api;

  /// Creates an instance of [ReportingClient].
  ReportingClient(Client client, String baseUrl)
      : _api = DoubleclickbidmanagerApi(client, rootUrl: baseUrl);

  /// Gets the CPM of the line item with [advertiserId] and [lineItemId].
  ///
  /// Throws an [ApiRequestError] if there is an error with the reporting API.
  /// Throws an [ArgumentError] if any data is missing from the report or the
  /// report is not found. Returns the CPM value as a double.
  Future<double> getLineItemCpm(Int64 advertiserId, Int64 lineItemId) async {
    return double.parse(await _getLineItemMetric(
        advertiserId, lineItemId, 'METRIC_REVENUE_ECPM_ADVERTISER'));
  }

  /// Gets the previous day metric value of the line item with [advertiserId]
  /// and [lineItemId].
  ///
  /// The list of possible [metric] values can be found here:
  /// https://developers.google.com/bid-manager/v1.1/filters-metrics
  ///
  /// Throws an [ApiRequestError] if there is an error with the reporting API.
  /// Throws an [ArgumentError] if any data is missing from the report or the
  /// report is not found. Returns the metric value as a string.
  Future<String> _getLineItemMetric(
      Int64 advertiserId, Int64 lineItemId, String metric) async {
    const dataRange = 'PREVIOUS_DAY';
    final metrics = [metric];
    final groupBys = [
      'FILTER_LINE_ITEM',
      'FILTER_DATE',
      'FILTER_ADVERTISER_CURRENCY'
    ];

    // Creates the query for the line item.
    final queryId = await _createLineItemQuery(
        advertiserId, lineItemId, dataRange, metrics, groupBys);

    // Get the URL of the report of the created query.
    final url = await _getReportUrl(queryId);

    try {
      // Downloads the report and converts it into a map.
      final reportMap = await _reportToMap(url);

      return reportMap[metricToReportColumnName[metric]];
    } on ArgumentError {
      throw ArgumentError('Report with ID $queryId contains missing data.');
    }
  }

  /// Creates a query for a line item with [advertiserId] and [lineItemId].
  ///
  /// The [dataRange] specifies the range of the report. See
  /// [QueryMetadata.dataRange]. [metrics] is a list of metrics included in the
  /// report. [groupBys] specifies which filters the data is grouped by.
  ///
  /// Throws an [ApiRequestError] if there is an error with the reporting API.
  /// Returns the ID of the query.
  Future<String> _createLineItemQuery(Int64 advertiserId, Int64 lineItemId,
      String dataRange, List<String> metrics, List<String> groupBys) async {
    final request = Query()
      ..metadata = (QueryMetadata()
        ..title = 'LineItemQuery'
        ..format = 'CSV'
        ..dataRange = dataRange)
      ..params = (Parameters()
        ..metrics = metrics
        ..groupBys = groupBys
        ..filters = [
          (FilterPair()
            ..type = 'FILTER_ADVERTISER'
            ..value = advertiserId.toString()),
          (FilterPair()
            ..type = 'FILTER_LINE_ITEM'
            ..value = lineItemId.toString())
        ]);

    return (await _api.queries.createquery(request)).queryId;
  }

  /// Gets the URL of the report with [queryId].
  ///
  /// Throws an [ApiRequestError] if there is an error with the reporting API.
  Future<String> _getReportUrl(String queryId) async {
    final query = await _api.queries.getquery(queryId);
    return query.metadata.googleCloudStoragePathForLatestReport;
  }

  /// Extract the values in the report from [reportUrl] into a map.
  ///
  /// Throws an ArgumentError if report is not found or any data is missing.
  Future<Map<String, String>> _reportToMap(String reportUrl) async {
    // Sends an HTTP GET request to the [reportUrl].
    final response = await get(reportUrl);

    // Converts the response body which is in CSV format into a list.
    final rows = const CsvToListConverter()
        .convert(response.body, eol: '\n', shouldParseNumbers: false);

    // Converts the list into a map of keys and values.
    final map =
    Map.fromIterables(rows[0].cast<String>(), rows[1].cast<String>());

    return map;
  }
}
