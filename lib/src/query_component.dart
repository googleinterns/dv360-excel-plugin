import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:quiver/collection.dart';

import 'excel.dart';
import 'insertion_order_daily_spend.dart';
import 'json_js.dart';
import 'proto/insertion_order_query.pb.dart';
import 'public_api_parser.dart';
import 'query_service.dart';
import 'reporting_api_parser.dart';
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
class QueryComponent implements OnInit {
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

  @override
  void ngOnInit() async => await _excel.loadOffice();

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

    // Gets the earliest start date from the list of insertion orders.
    final minStartDate = _getMinStartDate(insertionOrders);

    // Uses DBM reporting APIs to get spent (currency based or
    // impression based) within time window [minStartDate, Now].
    // spendingMap has a [DailySpend] for each insertion order.
    final spendingMap =
        await _queryAndParseSpentData(minStartDate, DateTime.now());

    // Add spent to the list of insertion orders.
    _addSpentToInsertionOrders(insertionOrders, spendingMap);

    // Populate the spreadsheet.
    await _excel.populate(insertionOrders, highlightUnderpacing);
  }

  /// Fetches insertion order entity related data using DV360 public APIs,
  /// then return a list of parsed [InsertionOrder] instance.
  Future<List<InsertionOrder>> _queryAndParseInsertionOrderEntityData() async {
    final insertionOrderList = <InsertionOrder>[];
    var jsonResponse = '{}';

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
  Future<Multimap<String, InsertionOrderDailySpend>> _queryAndParseSpentData(
      DateTime startDate, DateTime endDate) async {
    try {
      // Creates a reporting query, and parses the queryId from response.
      final jsonCreateQueryResponse =
          await _queryService.execReportingCreateQuery(
              _queryType, advertiserId, insertionOrderId, startDate, endDate);
      final reportingQueryId = ReportingQueryParser.parseQueryIdFromJsonString(
          JsonJS.stringify(jsonCreateQueryResponse));

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
      return Multimap<String, InsertionOrderDailySpend>();
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

  DateTime _getMinStartDate(
          List<InsertionOrder> insertionOrders) =>
      insertionOrders
          .map((io) => Util.convertProtoDateToDateTime(
              io.budget.activeBudgetSegment.dateRange.startDate))
          .reduce((date, minDate) => date.isBefore(minDate) ? date : minDate);

  void _addSpentToInsertionOrders(List<InsertionOrder> insertionOrders,
      Multimap<String, InsertionOrderDailySpend> spendingMap) {
    for (final io in insertionOrders) {
      final budgetUnit = io.budget.budgetUnit;
      final flightStart = Util.convertProtoDateToDateTime(
          io.budget.activeBudgetSegment.dateRange.startDate);
      final flightEnd = Util.convertProtoDateToDateTime(
          io.budget.activeBudgetSegment.dateRange.endDate);

      final spent = spendingMap[io.insertionOrderId]
          .where((dailySpend) =>
              Util.isBetweenDates(dailySpend.date, flightStart, flightEnd))
          .map((dailySpend) => budgetUnit ==
                  InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
              ? dailySpend.revenue
              : dailySpend.impression)
          .reduce((spend, sum) => Util.addStringRevenue(spend, sum));

      io.spent = spent;
    }
  }
}
