import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:fixnum/fixnum.dart';

import 'gapi.dart';
import 'proto/insertion_order_query.pb.dart';

@Injectable()
class QueryService {
  static final reportingHttpPath =
      'https://www.googleapis.com/doubleclickbidmanager/v1.1/query';

  /// Executes the DV3 query and returns a future that will complete with
  /// a raw javascript object.
  Future<dynamic> execDV3Query(
      String advertiserId, String insertionOrderId) async {
    final dv3RequestArgs = RequestArgs(
        path: _generateQuery(advertiserId, insertionOrderId), method: 'GET');

    final responseCompleter = Completer<dynamic>();
    GoogleAPI.client
        .request(dv3RequestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(jsonResp);
    }));

    return responseCompleter.future;
  }

  /// Executes DBM reporting create query and returns a future that will
  /// complete with a raw javascript object.
  Future<dynamic> execReportingCreateQuery(
      String advertiserId,
      String insertionOrderId,
      InsertionOrder_Budget_BudgetSegment_DateRange dateRange) async {
    final reportingQuery = ReportingQueryParameter()
      ..metadata = (ReportingQueryParameter_Metadata()
          ..title = '"DV360-excel-plugin-query"'
        ..dataRange = '"CUSTOM_DATES"'
        ..format = '"EXCEL_CSV"')
      ..params = (ReportingQueryParameter_Params()
        ..metrics.add('"METRIC_REVENUE_USD"')
        ..groupBys.add('"FILTER_INSERTION_ORDER"')
        ..filters.add(ReportingQueryParameter_Params_Filters()
          ..type = '"FILTER_ADVERTISER"'
          ..value = advertiserId)
        ..filters.add(ReportingQueryParameter_Params_Filters()
          ..type = '"FILTER_INSERTION_ORDER"'
          ..value = insertionOrderId))
      ..reportDataStartTimeMs = Int64(DateTime(dateRange.startDate.year,
              dateRange.startDate.month, dateRange.startDate.day, 0)
          .millisecondsSinceEpoch)
      ..reportDataEndTimeMs = Int64(DateTime(dateRange.endDate.year,
              dateRange.endDate.month, dateRange.endDate.day, 0)
          .add(Duration(days: 1))
          .millisecondsSinceEpoch);

    final reportingRequestArgs = RequestArgs(
        path: reportingHttpPath,
        method: 'POST',
        body: reportingQuery.toProto3Json().toString());

    final responseCompleter = Completer<dynamic>();
    GoogleAPI.client
        .request(reportingRequestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(jsonResp);
    }));

    return responseCompleter.future;
  }

  /// Executes DBM reporting getQuery and returns a future that will
  /// complete with a raw javascript object.
  Future<dynamic> execReportingGetQuery(String queryId) {
    final requestArgs = RequestArgs(
        path:
            'https://www.googleapis.com/doubleclickbidmanager/v1.1/query/$queryId',
        method: 'GET');

    final responseCompleter = Completer<dynamic>();
    GoogleAPI.client
        .request(requestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(jsonResp);
    }));

    return responseCompleter.future;
  }

  /// Read the report from google storage location specified by [downloadPath].
  Future<dynamic> execReportingDownload(String downloadPath) {
    final requestArgs = RequestArgs(path: downloadPath, method: 'GET');

    final responseCompleter = Completer<dynamic>();
    GoogleAPI.client
        .request(requestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(rawResp);
    }));

    return responseCompleter.future;
  }

  /// Generates query based on user inputs.
  static String _generateQuery(String advertiserId, String insertionOrderId) {
    return 'https://displayvideo.googleapis.com/v1/advertisers/$advertiserId/'
        'insertionOrders/$insertionOrderId';
  }
}
