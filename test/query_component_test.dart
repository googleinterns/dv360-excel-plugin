@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/excel.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'query_component_po.dart';
import 'query_component_test.template.dart' as ng;
import 'util/js_injector.dart';

class MockExcelDart extends Mock implements ExcelDart {}

@Component(
  selector: 'query-test-component',
  template: '''
    <query></query>
  ''',
  directives: [QueryComponent],
)
class QueryTestComponent implements OnInit {
  @override
  void ngOnInit() => JSInjector.injectOfficeJS();
}

@GenerateInjector([
  Provider(ExcelDart, useClass: MockExcelDart),
])
final InjectorFactory injector = ng.injector$Injector;

void main() {
  NgTestBed testBed;
  NgTestFixture<QueryTestComponent> fixture;
  QueryComponentPageObject queryComponentPO;
  MockExcelDart mockExcel;

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory,
        rootInjector: injector);
    fixture = await testBed.create(
        beforeComponentCreated: (injector) =>
            mockExcel = injector.get(ExcelDart));
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
  });

  tearDown(disposeAnyRunningTest);

  test('populate button clicks invokes exec()', () async {
    await queryComponentPO.populate();
    verify(mockExcel.exec());
  });
}
