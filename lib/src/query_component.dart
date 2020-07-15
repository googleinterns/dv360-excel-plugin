import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

import 'excel.dart';
import 'public_api_parser.dart';
import 'json_js.dart';
import 'proto/insertion_order_query.pb.dart';
import 'query_service.dart';
import 'reporting_query_parser.dart';
import 'util.dart';

@Component(
  selector: 'query',
  template: '''
    <input [(ngModel)]="advertiserId" 
           placeholder="Advertiser ID: 164337" debugId="advertiser-id-input">
    <input [(ngModel)]="insertionOrderId" 
           placeholder="Insertion Order ID: 8127549" debugId="io-id-input">
    <br>

    <input type="radio" [(ngModel)]="advertiserQuery" name="advertiser-query">
    <label for="advertiser-query">By advertiser</label><br>
    <input type="radio" [(ngModel)]="insertionOrderQuery" name="advertiser-query">
    <label for="advertiser-query">By insertion order</label><br>
    
    <input type="checkbox" [(ngModel)]="highlightUnderpacing"
           debugId="underpacing" name="underpacing">
    <label for="underpacing">Highlight underpacing insertion orders</label><br>
    
    <button (click)="onClick()" debugId="populate-btn">
    {{buttonName}}
    </button>
  ''',
  providers: [
    ClassProvider(QueryService),
    ClassProvider(ExcelDart),
    FORM_PROVIDERS,
  ],
  directives: [coreDirectives, formDirectives],
)
class QueryComponent {
  final buttonName = 'populate';
  final QueryService _queryService;
  final ExcelDart _excel;

  QueryType _queryType;

  String advertiserId;
  String insertionOrderId;
  bool highlightUnderpacing = false;

  // Radio button states with byAdvertiser selected as default.
  RadioButtonState advertiserQuery = RadioButtonState(true, 'byAdvertiser');
  RadioButtonState insertionOrderQuery = RadioButtonState(false, 'byIO');

  QueryComponent(this._queryService, this._excel);

  void onClick() async {
    // Determines the query type from radio buttons.
    _queryType = advertiserQuery.checked
        ? QueryType.byAdvertiser
        : QueryType.byInsertionOrder;

    // Uses DV360 public APIs to fetch entity data.
    var insertionOrders = await _queryAndParseInsertionOrderEntityData();

    // If [_queryType.byAdvertiser], filters out insertion orders
    // that are not in-flight.
    insertionOrders = _queryType == QueryType.byAdvertiser
        ? _filterInFlightInsertionOrders(insertionOrders)
        : insertionOrders;

    // TODO: update reporting query to deal with multiple IOs.
    // Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/61
    final insertionOrder = insertionOrders.first;

    // Gets dateRange for the active budget segment.
    final activeDateRange = insertionOrder.budget.activeBudgetSegment.dateRange;

    // Uses DBM reporting APIs to get revenue data within [activeDateRange].
    final revenueMap = await _queryAndParseRevenueSpentData(activeDateRange);

    // Add revenue spent to the parsed Insertion Order.
    insertionOrder.spent = revenueMap[insertionOrder.insertionOrderId] ?? '';

    // Populate the spreadsheet.
    await _excel.populate(insertionOrders, highlightUnderpacing);
  }

  /// Fetches insertion order entity related data using DV360 public APIs,
  /// then return a list of parsed [InsertionOrder] instance.
  Future<List<InsertionOrder>> _queryAndParseInsertionOrderEntityData() async {
    final insertionOrderList = <InsertionOrder>[];
    var jsonResponse = '';

    do {
      // Gets the nextPageToken, and having an empty token
      // doesn't affect the query.
      final nextPageToken = PublicApiParser.parseNextPageToken(jsonResponse);

      // Executes dv360 query, parses the response and adds results to the list.
      final response = await _queryService.execDV3Query(
          _queryType, nextPageToken, advertiserId, insertionOrderId);
      jsonResponse = JsonJS.stringify(response);

      // Adds all insertion orders in this iteration to the list.
      insertionOrderList
          .addAll(PublicApiParser.parseInsertionOrders(jsonResponse));
    } while (PublicApiParser.parseNextPageToken(jsonResponse).isNotEmpty);

    return insertionOrderList;
  }

  /// Fetches revenue spent data using DBM reporting APIs,
  /// then return a map with <ioID, revenue> key-value pairs.
  Future<Map<String, String>> _queryAndParseRevenueSpentData(
      InsertionOrder_Budget_BudgetSegment_DateRange dateRange) async {
    // Creates a reporting query, and parses the queryId from response.
    final jsonCreateQueryResponse = await _queryService
        .execReportingCreateQuery(advertiserId, insertionOrderId, dateRange);
    final reportingQueryId = ReportingQueryParser.parseQueryIdFromJsonString(
        JsonJS.stringify(jsonCreateQueryResponse));

    try {
      // Uses the queryId to get the report download path.
      final jsonGetQueryResponse =
          await _queryService.execReportingGetQuery(reportingQueryId);
      final reportingDownloadPath =
          ReportingQueryParser.parseDownloadPathFromJsonString(
              JsonJS.stringify(jsonGetQueryResponse));

      // Downloads the report and parse the response into a revenue map.
      final report =
          await _queryService.execReportingDownload(reportingDownloadPath);

      return ReportingQueryParser.parseRevenueFromJsonString(report);
    } catch (e) {
      /// TODO: proper error handling.
      /// Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/52.
      return <String, String>{};
    }
  }

  List<InsertionOrder> _filterInFlightInsertionOrders(
      List<InsertionOrder> insertionOrders) {
    return insertionOrders
        .where((io) =>
            io.budget.activeBudgetSegment !=
            InsertionOrder_Budget_BudgetSegment())
        .toList();
  }
}
