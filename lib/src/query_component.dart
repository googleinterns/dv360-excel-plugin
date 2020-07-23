import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:quiver/collection.dart';

import 'excel.dart';
import 'insertion_order_daily_spend.dart';
import 'proto/insertion_order_query.pb.dart';
import 'public_api_parser.dart';
import 'query_service.dart';
import 'reporting_api_parser.dart';
import 'util.dart';

@Component(
  selector: 'query',
  templateUrl: 'query_component.html',
  providers: [
    ClassProvider(QueryService),
    ClassProvider(ExcelDart),
    FORM_PROVIDERS,
  ],
  directives: [coreDirectives, formDirectives],
)
class QueryComponent implements OnInit {
  final populateButtonName = 'populate';
  final underpacingCheckBoxName = 'Highlight underpacing insertion orders';
  final QueryService _queryService;
  final ExcelDart _excel;

  // Default selection is byAdvertiser.
  QueryType queryType = QueryType.byAdvertiser;
  List<QueryType> queryTypeChoices = QueryType.values;

  String advertiserId;
  String mediaPlanId;
  String insertionOrderId;
  bool highlightUnderpacing = false;

  QueryComponent(this._queryService, this._excel);

  @override
  void ngOnInit() async => await _excel.loadOffice();

  void onClick() async {
    // TODO: Error handling when the necessary ids are not typed in.
    // Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/52

    // Uses DV360 public APIs to fetch entity data.
    List<InsertionOrder> insertionOrders =
        await _queryAndParseInsertionOrderEntityData();

    // Early return if the query returns no insertion orders.
    if (insertionOrders.isEmpty) return;

    // If query type is not by insertion order, filters out insertion orders
    // that are not in-flight.
    insertionOrders = queryType == QueryType.byInsertionOrder
        ? insertionOrders
        : _filterInFlightInsertionOrders(insertionOrders);

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

  /// Convert [queryType] enum to a user-friendly string.
  ///
  /// Used in [query_component.html] as the radio button text.
  String getQueryTypeName(QueryType queryType) => queryType.name;

  /// Convert [queryType] enum to a short string that contains no space.
  ///
  /// Used in [query_component.html] as part of the radio button id.
  String getQueryTypeShortName(QueryType queryType) => queryType.shortName;

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
      jsonResponse = await _queryService.execDV3Query(queryType, nextPageToken,
          advertiserId, mediaPlanId, insertionOrderId);

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
          await _queryService.execReportingCreateQuery(queryType, advertiserId,
              mediaPlanId, insertionOrderId, startDate, endDate);

      final reportingQueryId = ReportingQueryParser.parseQueryIdFromJsonString(
          jsonCreateQueryResponse);

      // Uses the queryId to get the report download path.
      final jsonGetQueryResponse =
          await _queryService.execReportingGetQuery(reportingQueryId);

      final reportingDownloadPath =
          ReportingQueryParser.parseDownloadPathFromJsonString(
              jsonGetQueryResponse);

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
          List<InsertionOrder> insertionOrders) =>
      insertionOrders
          .where((io) =>
              io.budget.activeBudgetSegment !=
              InsertionOrder_Budget_BudgetSegment())
          .toList();

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
