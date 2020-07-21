@TestOn('browser')

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/excel.dart';
import 'package:dv360_excel_plugin/src/proto/insertion_order_query.pb.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:dv360_excel_plugin/src/query_service.dart';
import 'package:dv360_excel_plugin/src/util.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'query_component_test.template.dart' as ng;
import 'testing/query_component_po.dart';

@Injectable()
class MockQueryService extends Mock implements QueryService {
  MockQueryService._private();

  static final MockQueryService _singleton = MockQueryService._private();

  factory MockQueryService() {
    return _singleton;
  }
}

@Injectable()
class MockExcelDart extends Mock implements ExcelDart {
  MockExcelDart._private();

  static final MockExcelDart _singleton = MockExcelDart._private();

  factory MockExcelDart() {
    return _singleton;
  }
}

@Directive(
  selector: '[override]',
  providers: [
    ClassProvider(QueryService, useClass: MockQueryService),
    ClassProvider(ExcelDart, useClass: MockExcelDart)
  ],
)
class OverrideDirective {}

@Component(
  selector: 'query-test-component',
  template: '<query override></query>',
  directives: [
    QueryComponent,
    OverrideDirective,
  ],
)
class QueryTestComponent {}

void main() {
  NgTestBed testBed;
  NgTestFixture<QueryTestComponent> fixture;
  QueryComponentPageObject queryComponentPO;
  MockQueryService mockQueryService;
  MockExcelDart mockExcelDart;

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
    mockQueryService = MockQueryService();
    mockExcelDart = MockExcelDart();
  });

  tearDown(disposeAnyRunningTest);

  group('radio button clicks change QueryType:', () {
    test(
        'selecting byAdvertiser invokes execDV3Query(Query.byAdvertiser, '
        ', null, null, null)', () async {
      await (queryComponentPO.selectByAdvertiser());
      await (queryComponentPO.clickPopulate());
      verify(mockQueryService.execDV3Query(
          QueryType.byAdvertiser, '', null, null, null));
    });

    test(
        'selecting byAdvertiser invokes execDV3Query(Query.byAdvertiser, '
        ', null, null, null)', () async {
      await (queryComponentPO.selectByMediaPlan());
      await (queryComponentPO.clickPopulate());
      verify(mockQueryService.execDV3Query(
          QueryType.byMediaPlan, '', null, null, null));
    });

    test(
        'selecting byAdvertiser invokes execDV3Query(Query.byAdvertiser, '
        ', null, null, null)', () async {
      await (queryComponentPO.selectByIO());
      await (queryComponentPO.clickPopulate());
      verify(mockQueryService.execDV3Query(
          QueryType.byInsertionOrder, '', null, null, null));
    });

    test('only the last selection matters', () async {
      await (queryComponentPO.selectByIO());
      await (queryComponentPO.selectByAdvertiser());
      await (queryComponentPO.selectByMediaPlan());
      await (queryComponentPO.clickPopulate());
      verify(mockQueryService.execDV3Query(
          QueryType.byMediaPlan, '', null, null, null));
    });
  });

  group('populate-button clicks invokes functions:', () {
    const advertiserId = 'advertiser-id';
    const mediaPlanId = 'media-plan-id';
    const insertionOrderId = 'io-id';
    const queryId = 'query-id';
    const downloadLink = 'download-link';
    final startDate = DateTime(2020, 7, 1);

    setUp(() async {
      await queryComponentPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.typeMediaPlanId(mediaPlanId);
      await queryComponentPO.typeInsertionOrderId(insertionOrderId);

      await queryComponentPO.selectByAdvertiser();
      await queryComponentPO.selectUnderpacing();

      when(mockQueryService.execDV3Query(any, any, any, any, any))
          .thenAnswer((_) => Future.value('{"advertiserId":"$advertiserId",'
              '"campaignId":"$mediaPlanId",'
              '"insertionOrderId":"$insertionOrderId",'
              '"budget":{"budgetUnit":"BUDGET_UNIT_CURRENCY",'
              '"budgetSegments":[{"budgetAmountMicros":"100000",'
              '"dateRange":{"startDate":{"year":2020,"month":7,"day":1},'
              '"endDate":{"year":2020,"month":7,"day":31}}}]}}'));
      when(mockQueryService.execReportingCreateQuery(
              any, any, any, any, any, any))
          .thenAnswer((_) => Future.value('{"queryId": "$queryId"}'));
      when(mockQueryService.execReportingGetQuery(any)).thenAnswer((_) =>
          Future.value('{"metadata" : {"googleCloudStoragePathForLatestReport":'
              '"$downloadLink"}}'));
      when(mockQueryService.execReportingDownload(any))
          .thenAnswer((_) => Future.value('{"gapiRequest" : {"data" : {"body": '
              '"Insertion Order ID, Date, Revenue, Impression\\n'
              'io-id,2020/07/10,88.88,1000\\n"}}}'));

      await queryComponentPO.clickPopulate();
    });

    test(
        'execDV3Query(QueryType.byAdvertiser, "", $advertiserId, $mediaPlanId, '
        '$insertionOrderId)', () async {
      verify(mockQueryService.execDV3Query(QueryType.byAdvertiser, '',
          advertiserId, mediaPlanId, insertionOrderId));
    });

    test(
        'execReportingCreateQuery(QueryType.byAdvertiser, $advertiserId,'
        '$mediaPlanId, $insertionOrderId, $startDate, any)', () async {
      verify(mockQueryService.execReportingCreateQuery(QueryType.byAdvertiser,
          advertiserId, mediaPlanId, insertionOrderId, startDate, any));
    });

    test('execReportingGetQuery($queryId)', () async {
      verify(mockQueryService.execReportingGetQuery(queryId));
    });

    test('execReportingDownload($downloadLink)', () async {
      verify(mockQueryService.execReportingDownload(downloadLink));
    });

    test('populate(insertionOrders, true)', () async {
      final insertionOrders = [
        InsertionOrder()
          ..advertiserId = advertiserId
          ..campaignId = mediaPlanId
          ..insertionOrderId = insertionOrderId
          ..displayName = ''
          ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED
          ..updateTime = ''
          ..pacing = InsertionOrder_Pacing()
          ..budget = (InsertionOrder_Budget()
            ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
            ..automationType =
                InsertionOrder_Budget_InsertionOrderAutomationType
                    .INSERTION_ORDER_AUTOMATION_TYPE_NONE
            ..activeBudgetSegment = (InsertionOrder_Budget_BudgetSegment()
              ..budgetAmountMicros = '100000'
              ..description = ''
              ..campaignBudgetId = ''
              ..dateRange = (InsertionOrder_Budget_BudgetSegment_DateRange()
                ..startDate =
                    (InsertionOrder_Budget_BudgetSegment_DateRange_Date()
                      ..year = 2020
                      ..month = 7
                      ..day = 1)
                ..endDate =
                    (InsertionOrder_Budget_BudgetSegment_DateRange_Date()
                      ..year = 2020
                      ..month = 7
                      ..day = 31))))
          ..spent = '88.88'
      ];
      verify(mockExcelDart.populate(insertionOrders, true));
    });
  });
}
