import 'dart:async';

import 'package:angular/angular.dart';
import 'package:fixnum/fixnum.dart';

import 'gapi.dart';
import 'google_api_request_args.dart';
import 'proto/insertion_order_query.pb.dart';
import 'util.dart';

@Injectable()
class QueryService {
  final GoogleApiDart _googleApiDart;

  QueryService(this._googleApiDart);

  /// Executes the DV3 query and returns a future that will complete with
  /// a raw javascript object.
  ///
  /// Having an empty [nextPageToken] will not affect the query.
  Future<String> execDV3Query(
          QueryType queryType,
          String nextPageToken,
          String advertiserId,
          String mediaPlanId,
          String insertionOrderId) =>
      _googleApiDart.request(_generateDV3Query(queryType, nextPageToken,
          advertiserId, mediaPlanId, insertionOrderId));

  /// Executes DBM reporting create query and returns a future that will
  /// complete with a raw javascript object.
  Future<String> execReportingCreateQuery(
          QueryType queryType,
          String advertiserId,
          String mediaPlanId,
          String insertionOrderId,
          DateTime startDate,
          DateTime endDate) =>
      _googleApiDart.request(_generateReportingQuery(queryType, advertiserId,
          mediaPlanId, insertionOrderId, startDate, endDate));

  /// Executes DBM reporting getQuery and returns a future that will
  /// complete with a raw javascript object.
  Future<String> execReportingGetQuery(String queryId) =>
      _googleApiDart.request((GoogleApiRequestArgsBuilder()
            ..path =
                'https://www.googleapis.com/doubleclickbidmanager/v1.1/query/$queryId'
            ..method = 'GET')
          .build());

  /// Read the report from google storage location specified by [downloadPath].
  Future<String> execReportingDownload(String downloadPath) =>
      _googleApiDart.request((GoogleApiRequestArgsBuilder()
            ..path = downloadPath
            ..method = 'GET')
          .build());

  /// Generates query based on user inputs.
  static GoogleApiRequestArgs _generateDV3Query(
      QueryType queryType,
      String nextPageToken,
      String advertiserId,
      String mediaPlanId,
      String insertionOrderId) {
    const entityStatusFilter = 'filter=entityStatus="ENTITY_STATUS_ACTIVE"';
    final pageTokenFilter = 'pageToken=$nextPageToken';

    switch (queryType) {
      case QueryType.byAdvertiser:
        return (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$advertiserId/insertionOrders?'
                  '$entityStatusFilter&$pageTokenFilter'
              ..method = 'GET')
            .build();

      case QueryType.byMediaPlan:
        final mediaPlanFilter = 'filter=campaignId="$mediaPlanId"';
        return (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$advertiserId/insertionOrders?'
                  '$entityStatusFilter&$mediaPlanFilter&$pageTokenFilter'
              ..method = 'GET')
            .build();

      case QueryType.byInsertionOrder:
        return (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$advertiserId/insertionOrders/$insertionOrderId'
              ..method = 'GET')
            .build();

      default:
        return GoogleApiRequestArgsBuilder().build();
    }
  }

  /// Generates query based on user inputs.
  static GoogleApiRequestArgs _generateReportingQuery(
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
        return GoogleApiRequestArgsBuilder().build();
    }

    return (GoogleApiRequestArgsBuilder()
          ..path = 'https://www.googleapis.com/doubleclickbidmanager/v1.1/query'
          ..method = 'POST'
          ..body = parameter.toProto3Json().toString())
        .build();
  }
}
