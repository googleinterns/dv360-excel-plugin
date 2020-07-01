@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
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

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
    mockQueryService = MockQueryService();
  });

  tearDown(disposeAnyRunningTest);

  test('populate button clicks invokes execQuery()', () async {
    await queryComponentPO.clickExecQuery();
    verify(mockQueryService.execQuery(any, any));
  });
}
