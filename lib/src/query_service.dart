import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';
import 'package:fixnum/fixnum.dart';

import 'gapi.dart';
import 'json_js.dart';
import 'proto/insertion_order_query.pb.dart';
import 'util.dart';

@Injectable()
class QueryService {
  /// Executes the DV3 query and returns a future that will complete with
  /// a raw javascript object.
  ///
  /// Completer is used here to convert the callback method of [execute] into
  /// a future, so that we only proceed when the request finishes executing.
  /// Having an empty [nextPageToken] will not affect the query.
  Future<String> execDV3Query(QueryType queryType, String nextPageToken,
      String advertiserId, String mediaPlanId, String insertionOrderId) async {
    final responseCompleter = Completer<String>();
    GoogleAPI.client
        .request(_generateDV3Query(queryType, nextPageToken, advertiserId,
            mediaPlanId, insertionOrderId))
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(JsonJS.stringify(jsonResp));
    }));

    return responseCompleter.future;
  }

  /// Executes DBM reporting create query and returns a future that will
  /// complete with a raw javascript object.
  ///
  /// Completer used to convert the callback method of [execute] into a future.
  Future<String> execReportingCreateQuery(
      QueryType queryType,
      String advertiserId,
      String mediaPlanId,
      String insertionOrderId,
      DateTime startDate,
      DateTime endDate) async {
    final responseCompleter = Completer<String>();
    GoogleAPI.client
        .request(_generateReportingQuery(queryType, advertiserId, mediaPlanId,
            insertionOrderId, startDate, endDate))
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(JsonJS.stringify(jsonResp));
    }));

    return responseCompleter.future;
  }

  /// Executes DBM reporting getQuery and returns a future that will
  /// complete with a raw javascript object.
  ///
  /// Completer used to convert the callback method of [execute] into a future.
  Future<String> execReportingGetQuery(String queryId) {
    final requestArgs = RequestArgs(
        path:
            'https://www.googleapis.com/doubleclickbidmanager/v1.1/query/$queryId',
        method: 'GET');

    final responseCompleter = Completer<String>();
    GoogleAPI.client
        .request(requestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(JsonJS.stringify(jsonResp));
    }));

    return responseCompleter.future;
  }

  /// Read the report from google storage location specified by [downloadPath].
  ///
  /// Completer used to convert the callback method of [execute] into a future.
  Future<String> execReportingDownload(String downloadPath) {
    final requestArgs = RequestArgs(path: downloadPath, method: 'GET');

    final responseCompleter = Completer<String>();
    GoogleAPI.client
        .request(requestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(rawResp);
    }));

    return responseCompleter.future;
  }

  /// Generates query based on user inputs.
  static RequestArgs _generateDV3Query(
      QueryType queryType,
      String nextPageToken,
      String advertiserId,
      String mediaPlanId,
      String insertionOrderId) {
    const entityStatusFilter = 'filter=entityStatus="ENTITY_STATUS_ACTIVE"';
    final mediaPlanFilter = 'filter=campaignId="$mediaPlanId"';
    final pageTokenFilter = 'pageToken=$nextPageToken';

    switch (queryType) {
      case QueryType.byAdvertiser:
        return RequestArgs(
            path: 'https://displayvideo.googleapis.com/v1/advertisers/'
                '$advertiserId/insertionOrders?'
                '$entityStatusFilter&$pageTokenFilter',
            method: 'GET');

      case QueryType.byMediaPlan:
        return RequestArgs(
            path: 'https://displayvideo.googleapis.com/v1/advertisers/'
                '$advertiserId/insertionOrders?'
                '$entityStatusFilter&$mediaPlanFilter&$pageTokenFilter',
            method: 'GET');

      case QueryType.byInsertionOrder:
        return RequestArgs(
            path: 'https://displayvideo.googleapis.com/v1/advertisers/'
                '$advertiserId/insertionOrders/$insertionOrderId',
            method: 'GET');

      default:
        return RequestArgs();
    }
  }

  /// Generates query based on user inputs.
  static RequestArgs _generateReportingQuery(
      QueryType queryType,
      String advertiserId,
      String mediaPlanId,
      String insertionOrderId,
      DateTime startDate,
      DateTime endDate) {
    final parameter = ReportingQueryParameter()
      ..metadata = (ReportingQueryParameter_Metadata()
        ..title = '"DV360-excel-plugin-query"'
        ..dataRange = '"CUSTOM_DATES"'
        ..format = '"EXCEL_CSV"')
      ..params = (ReportingQueryParameter_Params()
        ..metrics.add('"METRIC_REVENUE_USD"')
        ..metrics.add('"METRIC_IMPRESSIONS"')
        ..groupBys.add('"FILTER_INSERTION_ORDER"')
        ..groupBys.add('"FILTER_DATE"')
        ..filters.add(ReportingQueryParameter_Params_Filters()
          ..type = '"FILTER_ADVERTISER"'
          ..value = advertiserId))
      ..reportDataStartTimeMs = Int64(startDate.millisecondsSinceEpoch)
      ..reportDataEndTimeMs = Int64(endDate.millisecondsSinceEpoch);

    switch (queryType) {
      case QueryType.byAdvertiser:
        break;

      case QueryType.byMediaPlan:
        parameter.params.filters.add(ReportingQueryParameter_Params_Filters()
          ..type = '"FILTER_MEDIA_PLAN"'
          ..value = mediaPlanId);
        break;

      case QueryType.byInsertionOrder:
        parameter.params.filters.add(ReportingQueryParameter_Params_Filters()
          ..type = '"FILTER_INSERTION_ORDER"'
          ..value = insertionOrderId);
        break;

      default:
        return RequestArgs();
    }

    return RequestArgs(
        path: 'https://www.googleapis.com/doubleclickbidmanager/v1.1/query',
        method: 'POST',
        body: parameter.toProto3Json().toString());
  }
}
