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
import 'package:pageloader/testing.dart';
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
    const advertiserId = '10000';

    const mediaPlanId1 = '20000';
    const mediaPlanId2 = '20001';

    const ioId1 = '30000';
    const ioId2 = '30001';
    const ioId3 = '30002';
    const ioId4 = '30003';

    final startDate = DateTime(2020, 7, 1);
    final endDate = DateTime(2020, 7, 31);

    const spending1 = '100';
    const spending2 = '200';
    const spending3 = '300';
    const spending4 = '400';

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

    const report1 = '$ioId1,2020/07/10,$spending1,1000\\n'
        '$ioId2,2020/07/10,$spending2,1000\\n'
        '$ioId3,2020/07/10,$spending3,1000\\n'
        '$ioId4,2020/07/10,$spending4,1000\\n';
    const report2 = '$ioId1,2020/07/10,$spending1,1000\\n'
        '$ioId2,2020/07/10,$spending2,1000\\n'
        '$ioId3,2020/07/10,$spending3,1000\\n';
    const report3 = '$ioId1,2020/07/10,$spending1,1000\\n';

    NgTestBed testBed;
    NgTestFixture<QueryTestComponent> fixture;
    QueryComponentPageObject queryComponentPO;
    QueryComponentAccordionPageObject queryComponentAccordionPO;
    MockQueryService mockQueryService;
    MockExcelDart mockExcelDart;

    List<InsertionOrder> expectedInput;
    Completer<String> reportCompleter;

    setUp(() async {
      testBed = NgTestBed.forComponent<QueryTestComponent>(
          ng.QueryTestComponentNgFactory);
      fixture = await testBed.create();
      final context =
          HtmlPageLoaderElement.createFromElement((fixture.rootElement));
      queryComponentPO = QueryComponentPageObject.create(context);
      queryComponentAccordionPO =
          QueryComponentAccordionPageObject.create(context);
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
      await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.clickPopulate();
      verify(mockQueryService.execDV3Query(QueryType.byAdvertiser, '',
          advertiserId, argThat(isNull), argThat(isNull)));
    });

    test('only the last selection on query type matters', () async {
      await queryComponentAccordionPO.selectByAdvertiser();
      await queryComponentAccordionPO.selectByMediaPlan();
      await queryComponentAccordionPO.selectByIO();
      await queryComponentAccordionPO.selectByAdvertiser();

      await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.clickPopulate();

      verify(mockQueryService.execDV3Query(QueryType.byAdvertiser, '',
          advertiserId, argThat(isNull), argThat(isNull)));
    });

    test('only the last selection on query type matters', () async {
      await queryComponentAccordionPO.selectByAdvertiser();
      await queryComponentAccordionPO.selectByMediaPlan();
      await queryComponentAccordionPO.selectByIO();
      await queryComponentAccordionPO.selectByAdvertiser();

      await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.clickPopulate();

      verify(mockQueryService.execDV3Query(QueryType.byAdvertiser, '',
          advertiserId, argThat(isNull), argThat(isNull)));
    });

    group('selecting ByAdvertiser panel with', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByAdvertiser();

        final multipleIOJsonString = '''
        {
          "insertionOrders": [
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId2, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId3, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId2, ioId4, startDate, endDate)}
          ]
        }
        ''';

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
            .thenAnswer((_) => reportCompleter.future);

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId2, startDate, endDate, spending2),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId3, startDate, endDate, spending3),
          generateInsertionOrder(
              advertiserId, mediaPlanId2, ioId4, startDate, endDate, spending4),
        ];
      });

      tearDown(() => clearInteractions(mockQueryService));

      test('no advertiser id disables the populate button', () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('highlighting unchecked invokes populate(multiple-IO, false)',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlighting checked invokes populate(multiple-IO, true)',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        verify(mockExcelDart.populate(expectedInput, true));
      });

      test(
          'correct ids invokes populate() and '
          'displays the spinner when populate() is running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        // waits for the fixture to update, but keeps populate() hanging.
        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test(
          'correct ids invokes populate() and '
          'hides the spinner when populate() finishes running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });
    });

    group('selecting ByMediaPlan panel with', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByMediaPlan();

        final multipleIOJsonString = '''
        {
          "insertionOrders": [
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId2, startDate, endDate)},
            ${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId3, startDate, endDate)}
          ]
        }
        ''';

        when(mockQueryService.execDV3Query(QueryType.byMediaPlan, '',
                advertiserId, mediaPlanId1, argThat(isNull)))
            .thenAnswer((_) => Future.value(multipleIOJsonString));
        when(mockQueryService.execReportingCreateQuery(QueryType.byMediaPlan,
                advertiserId, mediaPlanId1, argThat(isNull), startDate, any))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockQueryService.execReportingGetQuery(queryId))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockQueryService.execReportingDownload(downloadLink))
            .thenAnswer((_) => reportCompleter.future);

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId2, startDate, endDate, spending2),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId3, startDate, endDate, spending3),
        ];
      });

      tearDown(() => clearInteractions(mockQueryService));

      test('no advertiser id and no media plan id disables the populate button',
          () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('no advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('no media plan id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('non-integer media plan id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test(
          'highlight underpacing unchecked invokes populate(multiple-IO, false)',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report2)));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlight underpacing checked invokes populate(multiple-IO, true)',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report2)));
        verify(mockExcelDart.populate(expectedInput, true));
      });

      test(
          'correct ids invokes populate() and '
          'displays the spinner when populate() is running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        // waits for the fixture to update, but keeps populate() hanging.
        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test(
          'correct ids invokes populate() and '
          'hides the spinner when populate() finishes running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });
    });

    group('selecting ByInsertionOrder with', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByIO();

        final singleIOJsonString =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)}';

        when(mockQueryService.execDV3Query(QueryType.byInsertionOrder, '',
                advertiserId, argThat(isNull), ioId1))
            .thenAnswer((_) => Future.value(singleIOJsonString));
        when(mockQueryService.execReportingCreateQuery(
                QueryType.byInsertionOrder,
                advertiserId,
                argThat(isNull),
                ioId1,
                startDate,
                any))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockQueryService.execReportingGetQuery(queryId))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockQueryService.execReportingDownload(downloadLink))
            .thenAnswer((_) => reportCompleter.future);

        expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1)
        ];
      });

      tearDown(() => clearInteractions(mockQueryService));

      test('no advertiser id and no io id disables the populate button',
          () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('no advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('no io id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('non-integer io id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockQueryService.execDV3Query(any, any, any, any, any));
      });

      test('highlighting unchecked invokes populate(single-IO, false)',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report3)));
        verify(mockExcelDart.populate(expectedInput, false));
      });

      test('highlighting checked invokes populate(single-IO, true)', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report3)));
        verify(mockExcelDart.populate(expectedInput, true));
      });

      test(
          'correct ids invokes populate() and '
          'displays the spinner when populate() is running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        // waits for the fixture to update, but keeps populate() hanging.
        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test(
          'correct ids invokes populate() and '
          'hides the spinner when populate() finishes running', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });
    });
  });
}
