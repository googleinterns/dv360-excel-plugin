import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

import 'excel.dart';
import 'insertion_order_parser.dart';
import 'json_js.dart' as json;
import 'proto/insertion_order_query.pb.dart';
import 'query_service.dart';
import 'reporting_query_parser.dart';

@Component(
  selector: 'query',
  template: '''
    <input [(ngModel)]="advertiserId" 
           placeholder="Advertiser ID: 164337" debugId="advertiser-id-input">
    <input [(ngModel)]="insertionOrderId" 
           placeholder="Insertion Order ID: 8127549" debugId="io-id-input">
    <br>
    <input type="checkbox" [(ngModel)]="highlightUnderpacing"
           debugId="underpacing" name="underpacing">
    <label for="underpacing">Highlight underpacing insertion orders</label><br>
    <button (click)="onClick()" debugId="populate-btn">
    {{buttonName}}
    </button>
  ''',
  providers: [ClassProvider(QueryService), ClassProvider(ExcelDart)],
  directives: [coreDirectives, formDirectives],
)
class QueryComponent {
  final buttonName = 'populate';
  final QueryService _queryService;
  final ExcelDart _excel;

  String advertiserId;
  String insertionOrderId;

  bool highlightUnderpacing = false;

  QueryComponent(this._queryService, this._excel);

  void onClick() async {
    // Uses DV360 public APIs to fetch entity data.
    final insertionOrder = await _queryAndParseInsertionOrderEntityData();

    // Gets dateRange for the active budget segment.
    final activeDateRange = insertionOrder.budget.activeBudgetSegment.dateRange;

    // Uses DBM reporting APIs to get revenue data within [activeDateRange].
    final revenueMap = await _queryAndParseRevenueSpentData(activeDateRange);

    // Add revenue spent to the parsed Insertion Order.
    insertionOrder.spent = revenueMap[insertionOrder.insertionOrderId] ?? '';

    // Populate the spreadsheet.
    await _excel.populate([insertionOrder], highlightUnderpacing);
  }

  /// Fetches insertion order entity related data using DV360 public APIs,
  /// then return a parsed [InsertionOrder] instance.
  Future<InsertionOrder> _queryAndParseInsertionOrderEntityData() async {
    final response =
        await _queryService.execDV3Query(advertiserId, insertionOrderId);

    return InsertionOrderParser.parse(json.stringify(response));
  }

  /// Fetches revenue spent data using DBM reporting APIs,
  /// then return a map with <ioID, revenue> key-value pairs.
  Future<Map<String, String>> _queryAndParseRevenueSpentData(
      InsertionOrder_Budget_BudgetSegment_DateRange dateRange) async {
    // Creates a reporting query, and parses the queryId from response.
    final jsonCreateQueryResponse = await _queryService
        .execReportingCreateQuery(advertiserId, insertionOrderId, dateRange);
    final reportingQueryId = ReportingQueryParser.parseQueryIdFromJsonString(
        json.stringify(jsonCreateQueryResponse));

    try {
      // Uses the queryId to get the report download path.
      final jsonGetQueryResponse =
      await _queryService.execReportingGetQuery(reportingQueryId);
      final reportingDownloadPath =
      ReportingQueryParser.parseDownloadPathFromJsonString(
          json.stringify(jsonGetQueryResponse));

      // Downloads the report and parse the response into a revenue map.
      final report =
      await _queryService.execReportingDownload(reportingDownloadPath);

      return ReportingQueryParser.parseRevenueFromJsonString(report);
    } catch(e) {
      /// TODO: proper error handling.
      /// Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/52.
      return <String, String>{};
    }
  }
}
