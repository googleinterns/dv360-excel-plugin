import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:fixnum/fixnum.dart';

import 'gapi.dart';
import 'proto/insertion_order_query.pb.dart';
import 'util.dart';

@Injectable()
class QueryService {
  static final reportingHttpPath =
      'https://www.googleapis.com/doubleclickbidmanager/v1.1/query';

  /// Executes the DV3 query and returns a future that will complete with
  /// a raw javascript object.
  ///
  /// Completer is used here to convert the callback method of [execute] into
  /// a future, so that we only proceed when the request finishes executing.
  /// Having an empty [nextPageToken] will not affect the query.
  Future<dynamic> execDV3Query(QueryType queryType, String nextPageToken,
      String advertiserId, String insertionOrderId) async {
    final responseCompleter = Completer<dynamic>();
    GoogleAPI.client
        .request(_generateDV3Query(
            queryType, nextPageToken, advertiserId, insertionOrderId))
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(jsonResp);
    }));

    return responseCompleter.future;
  }

  /// Executes DBM reporting create query and returns a future that will
  /// complete with a raw javascript object.
  ///
  /// Completer used to convert the callback method of [execute] into a future.
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
  ///
  /// Completer used to convert the callback method of [execute] into a future.
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
  ///
  /// Completer used to convert the callback method of [execute] into a future.
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
  static RequestArgs _generateDV3Query(QueryType queryType,
      String nextPageToken, String advertiserId, String insertionOrderId) {
    switch (queryType) {
      case QueryType.byAdvertiser:
        {
          final filter = 'filter=entityStatus="ENTITY_STATUS_ACTIVE"';
          final pageToken = 'pageToken=$nextPageToken';
          return RequestArgs(
              path: 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$advertiserId/insertionOrders?$filter&$pageToken',
              method: 'GET');
        }

      case QueryType.byInsertionOrder:
        {
          return RequestArgs(
              path: 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$advertiserId/insertionOrders/$insertionOrderId',
              method: 'GET');
        }

      default:
        {
          return RequestArgs();
        }
    }
  }
}
