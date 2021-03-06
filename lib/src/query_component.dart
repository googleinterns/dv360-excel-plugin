import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:dv360_excel_plugin/src/javascript_api/google_api.dart';
import 'package:ng_bootstrap/ng_bootstrap.dart';
import 'package:quiver/collection.dart';

import 'data_model/insertion_order_daily_spend.dart';
import 'data_model/insertion_order_query.pb.dart';
import 'javascript_api/excel_api.dart';
import 'public_api_parser.dart';
import 'reporting_api_parser.dart';
import 'service/query_service.dart';
import 'util.dart';

@Component(
  selector: 'query',
  templateUrl: 'query_component.html',
  providers: [
    ClassProvider(ExcelDart),
    FORM_PROVIDERS,
    ClassProvider(GoogleApiDart),
    ClassProvider(QueryService),
  ],
  directives: [bsAccordionDirectives, BsInput, coreDirectives, formDirectives],
)
class QueryComponent {
  // Values used in html.
  static const queryTypeChoices = QueryType.values;
  static const requestSectionTitle = 'Request Parameter';
  static const advertiserParameterName = 'advertiserId';
  static const mediaPlanParameterName = 'campaignId';
  static const insertionOrderParameterName = 'insertionOrderId';
  static const numberOnlyPattern = '^[0-9]+\$';
  static const underpacingCheckBoxName =
      'Highlight underpacing insertion orders';
  static const populateButtonName = 'populate';

  // Stores accordion panel selection, default is byAdvertiser.
  QueryType queryType = QueryType.byAdvertiser;

  // Stores input box values.
  String advertiserId;
  String mediaPlanId;
  String insertionOrderId;

  // Stores checkbox value, default is false.
  bool highlightUnderpacing = false;

  // Controls when to show the spinner on the populate button.
  bool showSpinner = false;

  // Controls when to show the alert message.
  bool showAlert = false;
  String alertMessage;

  // Reporting api has 2 years as the default max lookup window.
  static final reportStartDate = DateTime(
      DateTime.now().year - 2, DateTime.now().month, DateTime.now().day);

  final QueryService _queryService;
  final ExcelDart _excel;

  QueryComponent(this._queryService, this._excel);

  /// Disables the populate button if missing required input ids or
  /// if the ids are not integers.
  ///
  /// Binds to the [disabled] attribute on the populate button.
  bool disablePopulateButton() {
    var invalid = false;
    final numberOnly = RegExp(numberOnlyPattern);
    switch (queryType) {
      case QueryType.byMediaPlan:
        invalid = mediaPlanId == null || !numberOnly.hasMatch(mediaPlanId);
        continue checkAdvertiser;

      case QueryType.byInsertionOrder:
        invalid =
            insertionOrderId == null || !numberOnly.hasMatch(insertionOrderId);
        continue checkAdvertiser;

      checkAdvertiser:
      case QueryType.byAdvertiser:
        return advertiserId == null ||
            !numberOnly.hasMatch(advertiserId) ||
            invalid;

      default:
        return false;
    }
  }

  void onClick() async {
    try {
      // All required parameters are filled in, show spinner and remove alert.
      showSpinner = true;
      showAlert = false;

      // Futures used to await DV3 public and DBM reporting requests.
      List<Future<dynamic>> apiRequestFutures = <Future<dynamic>>[];

      // Uses DV360 public APIs to fetch entity data.
      Future<List<InsertionOrder>> publicApiParsedResponse =
          _queryAndParseInsertionOrderEntityData();
      apiRequestFutures.add(publicApiParsedResponse);

      // Uses DBM reporting APIs to get spent (currency based or
      // impression based) within time window [reportStartDate, Now].
      Future<Multimap<String, InsertionOrderDailySpend>>
          reportingApiParsedResponse =
          _queryAndParseSpentData(reportStartDate, DateTime.now());
      apiRequestFutures.add(reportingApiParsedResponse);

      // Waits for all requests to finish.
      final responseList = await Future.wait(apiRequestFutures);
      var insertionOrders = responseList.first;
      final spendingMap = responseList.last;

      // Add spent to the list of insertion orders.
      _addSpentToInsertionOrders(insertionOrders, spendingMap);

      // Populate the spreadsheet.
      await _excel.populate(insertionOrders, highlightUnderpacing);

      // Removes spinner when query is complete.
      showSpinner = false;
    } on ParserResponseException catch (e) {
      showSpinner = false;
      showAlert = true;
      alertMessage = e.toString();
    }
  }

  /// Convert [queryType] enum to a user-friendly string.
  ///
  /// Used in [query_component.html] as the accordion panel header text.
  String getQueryTypeName(QueryType queryType) => queryType.name;

  /// Convert [queryType] enum to a short string that contains no space.
  ///
  /// Used in [query_component.html] as part of the accordion panel id.
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
  }

  void _addSpentToInsertionOrders(List<InsertionOrder> insertionOrders,
      Multimap<String, InsertionOrderDailySpend> spendingMap) {
    for (final io in insertionOrders) {
      // Continues if the spending map doesn't have spending data for this io.
      // Happens when an IO has no active spending data and no historical
      // spending data either (i.e. the IO is created recently).
      if (!spendingMap.containsKey(io.insertionOrderId)) continue;

      final budgetUnit = io.budget.budgetUnit;
      final flightStart = Util.convertProtoDateToDateTime(
          io.budget.activeBudgetSegment.dateRange.startDate);
      final flightEnd = Util.convertProtoDateToDateTime(
          io.budget.activeBudgetSegment.dateRange.endDate);

      // Fills in a prompt for spend when the flight is longer than reporting
      // api max lookup window.
      if (flightStart.isBefore(reportStartDate)) {
        io.spent = 'Spend is not available, please go to the website';
        continue;
      }

      final activeSpent = spendingMap[io.insertionOrderId]
          .where((dailySpend) =>
              Util.isBetweenDates(dailySpend.date, flightStart, flightEnd))
          .map((dailySpend) => budgetUnit ==
                  InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
              ? dailySpend.revenue
              : dailySpend.impression);

      // Continues if the spending map doesn't have spending data for this io
      // within [reportStartDate, now].
      // Happens when the IO has historical spending data but no active ones.
      if (activeSpent.isEmpty) continue;
      // Sums up and updates spent if otherwise.
      io.spent =
          activeSpent.reduce((spend, sum) => Util.addStringRevenue(spend, sum));
    }
  }
}
