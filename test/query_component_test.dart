@TestOn('browser')
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/query_builder.dart';
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
    ClassProvider(QueryBuilder, useClass: QueryBuilder),
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
  QueryBuilder queryBuilder;
  Random random;

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
    queryBuilder = QueryBuilder();
    mockQueryService = MockQueryService();
    random = Random();
  });

  tearDown(disposeAnyRunningTest);

  test('advertiser id and insertion order id have no initial value', () {
    expect(queryBuilder.insertionOrderId, isNull);
    expect(queryBuilder.advertiserId, isNull);
  });

  group('update:', () {
    String id;

    setUp(() async {
      id = random.nextInt(10000).toString();
      await queryComponentPO.typeAdvertiserId(id);
      await queryComponentPO.typeInsertionOrderId(id);
    });

    test('typing ids stores value back to QueryBuilder', () {
      expect(queryBuilder.advertiserId, id);
      expect(queryBuilder.insertionOrderId, id);
    });
  });

  group('clear:', () {
    String id;

    setUp(() async {
      id = random.nextInt(10000).toString();
      await queryComponentPO.typeAdvertiserId(id);
      await queryComponentPO.typeInsertionOrderId(id);
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
