@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/excel.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'testing/query_component_po.dart';
import 'query_component_test.template.dart' as ng;

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
    ClassProvider(ExcelDart, useClass: MockExcelDart),
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
  MockExcelDart mockExcel;

  setUp(() async {
    testBed = NgTestBed.forComponent<QueryTestComponent>(
        ng.QueryTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    queryComponentPO = QueryComponentPageObject.create(context);
    mockExcel = MockExcelDart();
  });

  tearDown(disposeAnyRunningTest);

  test('populate button clicks invokes exec()', () async {
    await queryComponentPO.clickPopulate();
    verify(mockExcel.exec());
  });
}
