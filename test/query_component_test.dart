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
  group('In $QueryComponent,', () {
    const emptyEntry = '';
    const advertiserId = 'advertiser-id';
    const mediaPlanIdA = 'media-plan-id-a';
    const ioIdA = 'io-id-a';

    final startDate = DateTime(2020, 7, 1);
    final endDate = DateTime(2020, 7, 31);

    const spendingA = '100';

    const queryId = 'query-id';
    const downloadLink = 'download-link';

    const reportingCreateQueryApiJsonResponse = '{"queryId": "$queryId"}';
    const reportingGetQueryApiJsonResponse = '''
    {
      "metadata": {
        "googleCloudStoragePathForLatestReport": "$downloadLink"
      }
    } 
    ''';

    NgTestBed testBed;
    NgTestFixture<QueryTestComponent> fixture;
    QueryComponentPageObject queryComponentPO;
    QueryComponentRadioButtonPageObject queryComponentRadioButtonPO;
    MockQueryService mockQueryService;
    MockExcelDart mockExcelDart;

    setUp(() async {
      testBed = NgTestBed.forComponent<QueryTestComponent>(
          ng.QueryTestComponentNgFactory);
      fixture = await testBed.create();
      final context =
          HtmlPageLoaderElement.createFromElement((fixture.rootElement));
      queryComponentPO = QueryComponentPageObject.create(context);
      queryComponentRadioButtonPO =
          QueryComponentRadioButtonPageObject.create(context);
      mockQueryService = MockQueryService();
      mockExcelDart = MockExcelDart();
    });

    tearDown(disposeAnyRunningTest);

    String generateInsertionOrderJsonString(
            String advertiserId,
            String mediaPlanId,
            String ioId,
            DateTime startDate,
            DateTime endDate) =>
        '''
      {
        "advertiserId": "$advertiserId",
        "campaignId": "$mediaPlanId",
        "insertionOrderId": "$ioId",
        "budget": {
          "budgetUnit": "BUDGET_UNIT_CURRENCY",
          "budgetSegments": [{
            "dateRange": {
              "startDate": {
                "year": ${startDate.year},
                "month": ${startDate.month},
                "day": ${startDate.day}
              },
              "endDate": {
                "year": ${endDate.year},
                "month": ${endDate.month},
                "day": ${endDate.day}
              }
            }
          }]
        }
      }
      ''';

    String generateReport(String report) => '''
      {
        "gapiRequest": {
          "data": {
            "body": "Insertion Order ID, Date, Revenue, Impression\\n$report"
          }
        }
      }
      ''';

    InsertionOrder generateInsertionOrder(
            String advertiserId,
            String mediaPlanId,
            String ioId,
            DateTime startDate,
            DateTime endDate,
            String spent) =>
        InsertionOrder()
          ..advertiserId = advertiserId
          ..campaignId = mediaPlanId
          ..insertionOrderId = ioId
          ..displayName = emptyEntry
          ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED
          ..updateTime = emptyEntry
          ..pacing = InsertionOrder_Pacing()
          ..budget = (InsertionOrder_Budget()
            ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
            ..automationType =
                InsertionOrder_Budget_InsertionOrderAutomationType
                    .INSERTION_ORDER_AUTOMATION_TYPE_NONE
            ..activeBudgetSegment = (InsertionOrder_Budget_BudgetSegment()
              ..budgetAmountMicros = emptyEntry
              ..description = emptyEntry
              ..dateRange = (InsertionOrder_Budget_BudgetSegment_DateRange()
                ..startDate =
                    (InsertionOrder_Budget_BudgetSegment_DateRange_Date()
                      ..year = startDate.year
                      ..month = startDate.month
                      ..day = startDate.day)
                ..endDate =
                    (InsertionOrder_Budget_BudgetSegment_DateRange_Date()
                      ..year = endDate.year
                      ..month = endDate.month
                      ..day = endDate.day))
              ..campaignBudgetId = emptyEntry))
          ..spent = spent;

    test('making no selection defaults to ByAdvertiser', () async {
      await queryComponentPO.clickPopulate();
      verify(mockQueryService.execDV3Query(
          QueryType.byAdvertiser, any, any, any, any));
    });

    test('only the last selection on query type matters', () async {
      await queryComponentRadioButtonPO.selectByAdvertiser();
      await queryComponentRadioButtonPO.selectByMediaPlan();
      await queryComponentRadioButtonPO.selectByIO();
      await queryComponentPO.clickPopulate();
      verify(mockQueryService.execDV3Query(
          QueryType.byInsertionOrder, any, any, any, any));
    });

    group('selecting ByAdvertiser with', () {
      const mediaPlanIdB = 'media-plan-id-b';
      const ioIdB = 'io-id-b';
      const ioIdC = 'io-id-c';
      const ioIdD = 'io-id-d';
      const spendingB = '200';
      const spendingC = '300';
      const spendingD = '400';
      List<InsertionOrder> expectedInput;

      setUp(() async {
        await queryComponentRadioButtonPO.selectByAdvertiser();
        await queryComponentPO.typeAdvertiserId(advertiserId);

        final multipleIOJsonString = '''
        {
          "insertionOrders": [
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdA, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdB, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdC, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdB, ioIdD, startDate, endDate)}
          ]
        }
        ''';
        final report = '$ioIdA,2020/07/10,$spendingA,1000\\n'
            '$ioIdB,2020/07/10,$spendingB,1000\\n'
            '$ioIdC,2020/07/10,$spendingC,1000\\n'
            '$ioIdD,2020/07/10,$spendingD,1000\\n';

        when(mockQueryService.execDV3Query(QueryType.byAdvertiser, '',
                advertiserId, argThat(isNull), argThat(isNull)))
            .thenAnswer((_) => Future.value(multipleIOJsonString));
        when(mockQueryService.execReportingCreateQuery(QueryType.byAdvertiser,
                advertiserId, argThat(isNull), argThat(isNull), startDate, any))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockQueryService.execReportingGetQuery(queryId))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockQueryService.execReportingDownload(downloadLink))
            .thenAnswer((_) => Future.value(generateReport(report)));

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdA, startDate, endDate, spendingA),
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdB, startDate, endDate, spendingB),
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdC, startDate, endDate, spendingC),
          generateInsertionOrder(
              advertiserId, mediaPlanIdB, ioIdD, startDate, endDate, spendingD),
        ];
      });

      test(
          'highlight underpacing unchecked invokes populate(multiple-IO, false)',
          () async {
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlight underpacing checked invokes populate(multiple-IO, true)',
          () async {
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, true));
      });
    });

    group('selecting ByMediaPlan with', () {
      const ioIdB = 'io-id-b';
      const ioIdC = 'io-id-c';
      const spendingB = '200';
      const spendingC = '300';
      List<InsertionOrder> expectedInput;

      setUp(() async {
        await queryComponentRadioButtonPO.selectByMediaPlan();
        await queryComponentPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.typeMediaPlanId(mediaPlanIdA);

        final multipleIOJsonString = '''
        {
          "insertionOrders": [
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdA, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdB, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdC, startDate, endDate)}
          ]
        }
        ''';
        final report = '$ioIdA,2020/07/10,$spendingA,1000\\n'
            '$ioIdB,2020/07/10,$spendingB,1000\\n'
            '$ioIdC,2020/07/10,$spendingC,1000\\n';

        when(mockQueryService.execDV3Query(QueryType.byMediaPlan, '',
                advertiserId, mediaPlanIdA, argThat(isNull)))
            .thenAnswer((_) => Future.value(multipleIOJsonString));
        when(mockQueryService.execReportingCreateQuery(QueryType.byMediaPlan,
                advertiserId, mediaPlanIdA, argThat(isNull), startDate, any))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockQueryService.execReportingGetQuery(queryId))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockQueryService.execReportingDownload(downloadLink))
            .thenAnswer((_) => Future.value(generateReport(report)));

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdA, startDate, endDate, spendingA),
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdB, startDate, endDate, spendingB),
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdC, startDate, endDate, spendingC),
        ];
      });

      test(
          'highlight underpacing unchecked invokes populate(multiple-IO, false)',
          () async {
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlight underpacing checked invokes populate(multiple-IO, true)',
          () async {
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, true));
      });
    });

    group('selecting ByMediaPlan with', () {
      List<InsertionOrder> expectedInput;

      setUp(() async {
        await queryComponentRadioButtonPO.selectByIO();
        await queryComponentPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.typeInsertionOrderId(ioIdA);

        final singleIOJsonString =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanIdA, ioIdA, startDate, endDate)}';
        final report = '$ioIdA,2020/07/10,$spendingA,1000\\n';

        when(mockQueryService.execDV3Query(QueryType.byInsertionOrder, '',
                advertiserId, argThat(isNull), ioIdA))
            .thenAnswer((_) => Future.value(singleIOJsonString));
        when(mockQueryService.execReportingCreateQuery(
                QueryType.byInsertionOrder,
                advertiserId,
                argThat(isNull),
                ioIdA,
                startDate,
                any))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockQueryService.execReportingGetQuery(queryId))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockQueryService.execReportingDownload(downloadLink))
            .thenAnswer((_) => Future.value(generateReport(report)));

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanIdA, ioIdA, startDate, endDate, spendingA)
        ];
      });

      test('highlight underpacing unchecked invokes populate(single-IO, false)',
          () async {
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlight underpacing checked invokes populate(single-IO, true)',
          () async {
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for all button click operations to finish.
        await Future.delayed(Duration(seconds: 2));
        verify(mockExcelDart.populate(expectedInput, true));
      });
    });
  });
}
