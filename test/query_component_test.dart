@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/dv360_query_builder.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:dv360_excel_plugin/src/query_service.dart';
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

@Directive(
  selector: '[override]',
  providers: [
    ClassProvider(QueryService, useClass: MockQueryService),
    ClassProvider(DV360QueryBuilder, useClass: DV360QueryBuilder),
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
  DV360QueryBuilder queryBuilder;

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
    queryBuilder = DV360QueryBuilder();
    mockQueryService = MockQueryService();
  });

  tearDown(disposeAnyRunningTest);

  test('advertiser id and insertion order id have no initial value', () {
    expect(queryBuilder.insertionOrderId, isNull);
    expect(queryBuilder.advertiserId, isNull);
  });

  group('update:', () {
    final advertiserId = '111111';
    final insertionOrderId = '2222222';

    setUp(() async {
      await queryComponentPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.typeInsertionOrderId(insertionOrderId);
    });

    test('typing ids stores value back to QueryBuilder', () {
      expect(queryBuilder.advertiserId, advertiserId);
      expect(queryBuilder.insertionOrderId, insertionOrderId);
    });
  });

  group('clear:', () {
    final advertiserId = '111111';
    final insertionOrderId = '2222222';

    setUp(() async {
      await queryComponentPO.typeAdvertiserId(advertiserId);
      await queryComponentPO.typeInsertionOrderId(insertionOrderId);
      await queryComponentPO.clearAdvertiserId();
      await queryComponentPO.clearInsertionOrderId();
    });

    test('clearing input boxes erases the values stored', () {
      expect(queryBuilder.advertiserId, isEmpty);
      expect(queryBuilder.insertionOrderId, isEmpty);
    });
  });

  test('populate button clicks invokes execQuery()', () async {
    await queryComponentPO.clickPopulate();
    verify(mockQueryService.execQuery());
  });
}
