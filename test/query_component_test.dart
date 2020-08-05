@TestOn('browser')

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/excel.dart';
import 'package:dv360_excel_plugin/src/gapi.dart';
import 'package:dv360_excel_plugin/src/google_api_request_args.dart';
import 'package:dv360_excel_plugin/src/proto/insertion_order_query.pb.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:dv360_excel_plugin/src/util.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:pageloader/testing.dart';
import 'package:test/test.dart';

import 'query_component_test.template.dart' as ng;
import 'testing/query_component_po.dart';

@Injectable()
class MockGoogleApiDart extends Mock implements GoogleApiDart {
  MockGoogleApiDart._private();

  static final MockGoogleApiDart _singleton = MockGoogleApiDart._private();

  factory MockGoogleApiDart() {
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
    ClassProvider(GoogleApiDart, useClass: MockGoogleApiDart),
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
    final endDate = DateTime.now().add(Duration(days: 10));

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
    MockGoogleApiDart mockGoogleApiDart;
    MockExcelDart mockExcelDart;

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
      mockGoogleApiDart = MockGoogleApiDart();
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
      verify(mockGoogleApiDart.request(
          argThat(isDV3RequestWith(QueryType.byAdvertiser, advertiserId))));
    });

    test('only the last selection on query type matters', () async {
      await queryComponentAccordionPO.selectByAdvertiser();
      await queryComponentAccordionPO.selectByMediaPlan();
      await queryComponentAccordionPO.selectByIO();
      await queryComponentAccordionPO.selectByAdvertiser();

      await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.clickPopulate();

      verify(mockGoogleApiDart.request(
          argThat(isDV3RequestWith(QueryType.byAdvertiser, advertiserId))));
    });

    group('when spending data', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByIO();

        final singleIOJsonString =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)}';

        when(mockGoogleApiDart.request(argThat(isDV3RequestWith(
                QueryType.byInsertionOrder, advertiserId,
                ioId: ioId1))))
            .thenAnswer((_) => Future.value(singleIOJsonString));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byInsertionOrder, advertiserId, ioId: ioId1))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('is not available for $ioId1, the spent field defaults to 0',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        final reportWithNoSpendForIo1 = '$ioId2,2020/07/10,$spending2,1000\\n';
        await fixture.update((_) =>
            reportCompleter.complete(generateReport(reportWithNoSpendForIo1)));

        final expectedInputs = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, '0'),
        ];
        verify(mockExcelDart.populate(expectedInputs, any));
      });

      test(
          'is not available for $ioId1 during window [reportEarliestStart, Now],'
          'the spent field defaults to 0', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        final reportWithNoSpendForIo1 = '$ioId1,2000/07/10,$spending1,1000\\n';
        await fixture.update((_) =>
            reportCompleter.complete(generateReport(reportWithNoSpendForIo1)));

        final expectedInputs = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, '0'),
        ];
        verify(mockExcelDart.populate(expectedInputs, any));
      });

      test(
          'is available for $ioId1 but IO has flight longer than 2 years,'
          'the spent field displays the message', () async {
        final ioWithLongFlight =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, DateTime(2000, 7, 1), endDate)}';

        when(mockGoogleApiDart.request(argThat(isDV3RequestWith(
                QueryType.byInsertionOrder, advertiserId,
                ioId: ioId1))))
            .thenAnswer((_) => Future.value(ioWithLongFlight));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byInsertionOrder, advertiserId, ioId: ioId1))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);

        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        final expectedInputs = [
          generateInsertionOrder(
              advertiserId,
              mediaPlanId1,
              ioId1,
              DateTime(2000, 7, 1),
              endDate,
              'Spend is not available, please go to the website'),
        ];
        verify(mockExcelDart.populate(expectedInputs, any));
      });
    });

    group('when underpacing checkbox', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByIO();

        final singleIOJsonString =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)}';

        when(mockGoogleApiDart.request(argThat(isDV3RequestWith(
                QueryType.byInsertionOrder, advertiserId,
                ioId: ioId1))))
            .thenAnswer((_) => Future.value(singleIOJsonString));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byInsertionOrder, advertiserId, ioId: ioId1))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('is selected, populate(any, true) is invoked', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.selectUnderpacing();
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        verify(mockExcelDart.populate(any, true));
      });

      test('is not selected, populate(any, false) is invoked', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        verify(mockExcelDart.populate(any, false));
      });
    });

    group('raising QueryBuilderException', () {
      const expected = 'a QueryBuilderException has been raised';

      setUp(() async {
        when(mockGoogleApiDart.request(argThat(
                isDV3RequestWith(QueryType.byAdvertiser, advertiserId))))
            .thenAnswer((_) => throw ParserResponseException(expected));

        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        await fixture.update();
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('displays the alert and shows $expected', () async {
        final actual = await queryComponentPO.getAlertMessage();

        expect(queryComponentPO.queryAlert, exists);
        expect(actual, expected);
      });

      test('removes the spinner', () async {
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });
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

        when(mockGoogleApiDart.request(argThat(
                isDV3RequestWith(QueryType.byAdvertiser, advertiserId))))
            .thenAnswer((_) => Future.value(multipleIOJsonString));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byAdvertiser, advertiserId))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('no advertiser id disables the populate button', () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('valid advertiser id invokes populate() with correct IOs', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        final expectedInputs = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId2, startDate, endDate, spending2),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId3, startDate, endDate, spending3),
          generateInsertionOrder(
              advertiserId, mediaPlanId2, ioId4, startDate, endDate, spending4),
        ];
        verify(mockExcelDart.populate(expectedInputs, any));
      });

      test(
          'valid advertiser id displays the spinner when populate() is running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test(
          'valid advertiser id hides the spinner when populate() finishes running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });

      test(
          'correct ids raises no QueryBuilderException and hides the alert message',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.queryAlert, notExists);
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

        when(mockGoogleApiDart.request(argThat(isDV3RequestWith(
                QueryType.byMediaPlan, advertiserId,
                mediaPlanId: mediaPlanId1))))
            .thenAnswer((_) => Future.value(multipleIOJsonString));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byMediaPlan, advertiserId,
                    mediaPlanId: mediaPlanId1))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('no advertiser id and no media plan id disables the populate button',
          () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('no advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('no media plan id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('non-integer media plan id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('valid ids invokes populate() with correct IOs', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report2)));
        final expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId2, startDate, endDate, spending2),
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId3, startDate, endDate, spending3),
        ];
        verify(mockExcelDart.populate(expectedInput, any));
      });

      test('valid ids displays the spinner when populate() is running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test('valid ids hides the spinner when populate() finishes running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });

      test(
          'correct ids raises no QueryBuilderException and hides the alert message',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeMediaPlanId(mediaPlanId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.queryAlert, notExists);
      });
    });

    group('selecting ByInsertionOrder with', () {
      setUp(() async {
        reportCompleter = Completer<String>();

        await queryComponentAccordionPO.selectByIO();

        final singleIOJsonString =
            '${generateInsertionOrderJsonString(advertiserId, mediaPlanId1, ioId1, startDate, endDate)}';

        when(mockGoogleApiDart.request(argThat(isDV3RequestWith(
                QueryType.byInsertionOrder, advertiserId,
                ioId: ioId1))))
            .thenAnswer((_) => Future.value(singleIOJsonString));
        when(mockGoogleApiDart.request(argThat(
                isReportingCreateQueryRequestWith(
                    QueryType.byInsertionOrder, advertiserId, ioId: ioId1))))
            .thenAnswer(
                (_) => Future.value(reportingCreateQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingGetQueryRequestWith(queryId))))
            .thenAnswer((_) => Future.value(reportingGetQueryApiJsonResponse));
        when(mockGoogleApiDart
                .request(argThat(isReportingDownloadRequestWith(downloadLink))))
            .thenAnswer((_) => reportCompleter.future);
      });

      tearDown(() => clearInteractions(mockGoogleApiDart));

      test('no advertiser id and no io id disables the populate button',
          () async {
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('no advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('non-integer advertiser id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId('wrong-format-id');
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('no io id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('non-integer io id disables the populate button', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId('wrong-format-id');
        await queryComponentPO.clickPopulate();
        verifyNever(mockGoogleApiDart.request(any));
      });

      test('valid ids invokes populate() with correct IOs', () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report3)));
        final expectedInput = [
          generateInsertionOrder(
              advertiserId, mediaPlanId1, ioId1, startDate, endDate, spending1)
        ];
        verify(mockExcelDart.populate(expectedInput, any));
      });

      test('correct ids displays the spinner when populate() is running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        await fixture.update();
        expect(queryComponentPO.populateButtonSpinner, isVisible);
      });

      test('correct ids hides the spinner when populate() finishes running',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.populateButtonSpinner, notExists);
      });

      test(
          'correct ids raises no QueryBuilderException and hides the alert message',
          () async {
        await queryComponentAccordionPO.typeAdvertiserId(advertiserId);
        await queryComponentAccordionPO.typeInsertionOrderId(ioId1);
        await queryComponentPO.clickPopulate();

        // waits for the last operation execReportingDownload() to finish.
        await fixture
            .update((_) => reportCompleter.complete(generateReport(report1)));
        expect(queryComponentPO.queryAlert, notExists);
      });
    });
  });
}

class isDV3RequestWith extends Matcher {
  final QueryType _queryType;
  final String _advertiserId;
  final String _mediaPlanId;
  final String _ioId;

  isDV3RequestWith(this._queryType, this._advertiserId,
      {String mediaPlanId, String ioId})
      : _mediaPlanId = mediaPlanId,
        _ioId = ioId;

  @override
  Description describe(Description description) {
    description
        .add('DV3 $_queryType with $_advertiserId, $_mediaPlanId, $_ioId');
    return description;
  }

  @override
  bool matches(actual, Map matchState) {
    switch (_queryType) {
      case QueryType.byAdvertiser:
        final expected = (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$_advertiserId/insertionOrders?'
                  'filter=entityStatus="ENTITY_STATUS_ACTIVE"&pageToken='
              ..method = 'GET')
            .build();
        return actual == expected;

      case QueryType.byMediaPlan:
        final expected = (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$_advertiserId/insertionOrders?'
                  'filter=entityStatus="ENTITY_STATUS_ACTIVE"&'
                  'filter=campaignId="$_mediaPlanId"&'
                  'pageToken='
              ..method = 'GET')
            .build();
        return actual == expected;

      case QueryType.byInsertionOrder:
        final expected = (GoogleApiRequestArgsBuilder()
              ..path = 'https://displayvideo.googleapis.com/v1/advertisers/'
                  '$_advertiserId/insertionOrders/$_ioId'
              ..method = 'GET')
            .build();
        return actual == expected;

      default:
        return false;
    }
  }
}

class isReportingCreateQueryRequestWith extends Matcher {
  final QueryType _queryType;
  final String _advertiserId;
  final String _mediaPlanId;
  final String _ioId;

  isReportingCreateQueryRequestWith(this._queryType, this._advertiserId,
      {String mediaPlanId, String ioId})
      : _mediaPlanId = mediaPlanId,
        _ioId = ioId;

  @override
  Description describe(Description description) {
    description.add(
        'Reporting $_queryType createQuery with $_advertiserId, $_mediaPlanId, $_ioId');
    return description;
  }

  @override
  bool matches(actual, Map matchState) {
    if (actual.path !=
            'https://www.googleapis.com/doubleclickbidmanager/v1.1/query' ||
        actual.method != 'POST') {
      return false;
    }
    final indexOfReportDataStartTimeMs =
        actual.body.indexOf(', reportDataStartTimeMs');
    final actualBody = actual.body
        .substring(0, indexOfReportDataStartTimeMs)
        .replaceAll(RegExp(r'\s+'), '');

    switch (_queryType) {
      case QueryType.byAdvertiser:
        final expectedBody = '''
        {
          metadata: {title: "DV360-excel-plugin-query", 
                    dataRange: "CUSTOM_DATES", format: "EXCEL_CSV"}, 
          params: {
            metrics: ["METRIC_REVENUE_USD", "METRIC_IMPRESSIONS"], 
            groupBys: ["FILTER_INSERTION_ORDER", "FILTER_DATE"], 
            filters: [{type: "FILTER_ADVERTISER", value: $_advertiserId}]
         }
        '''
            .replaceAll(RegExp(r'\s+'), '');
        return expectedBody == actualBody;

      case QueryType.byMediaPlan:
        final expectedBody = '''
        {
          metadata: {title: "DV360-excel-plugin-query", 
                    dataRange: "CUSTOM_DATES", format: "EXCEL_CSV"}, 
          params: {
            metrics: ["METRIC_REVENUE_USD", "METRIC_IMPRESSIONS"], 
            groupBys: ["FILTER_INSERTION_ORDER", "FILTER_DATE"], 
            filters: [{type: "FILTER_ADVERTISER", value: $_advertiserId},
                      {type: "FILTER_MEDIA_PLAN", value: $_mediaPlanId}]
         }
        '''
            .replaceAll(RegExp(r'\s+'), '');
        return expectedBody == actualBody;

      case QueryType.byInsertionOrder:
        final expectedBody = '''
        {
          metadata: {title: "DV360-excel-plugin-query", 
                    dataRange: "CUSTOM_DATES", format: "EXCEL_CSV"}, 
          params: {
            metrics: ["METRIC_REVENUE_USD", "METRIC_IMPRESSIONS"], 
            groupBys: ["FILTER_INSERTION_ORDER", "FILTER_DATE"], 
            filters: [{type: "FILTER_ADVERTISER", value: $_advertiserId},
                      {type: "FILTER_INSERTION_ORDER", value: $_ioId}]
         }
        '''
            .replaceAll(RegExp(r'\s+'), '');
        return expectedBody == actualBody;

      default:
        return false;
    }
  }
}

class isReportingGetQueryRequestWith extends Matcher {
  final String _queryId;

  isReportingGetQueryRequestWith(this._queryId);

  @override
  Description describe(Description description) {
    description.add('Reporting getQuery with $_queryId');
    return description;
  }

  @override
  bool matches(actual, Map matchState) {
    final expected = (GoogleApiRequestArgsBuilder()
          ..path =
              'https://www.googleapis.com/doubleclickbidmanager/v1.1/query/$_queryId'
          ..method = 'GET')
        .build();
    return actual == expected;
  }
}

class isReportingDownloadRequestWith extends Matcher {
  final String _downloadPath;

  isReportingDownloadRequestWith(this._downloadPath);

  @override
  Description describe(Description description) {
    description.add('Reporting getQuery with $_downloadPath');
    return description;
  }

  @override
  bool matches(actual, Map matchState) {
    final expected = (GoogleApiRequestArgsBuilder()
          ..path = _downloadPath
          ..method = 'GET')
        .build();
    return actual == expected;
  }
}
