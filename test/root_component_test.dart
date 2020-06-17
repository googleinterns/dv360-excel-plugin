@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/root_component.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'root_component_po.dart';
import 'root_component_test.template.dart' as ng;
import 'util/js_injector.dart';

@Component(
  selector: 'root-test-component',
  template: '''
    <application-root></application-root>
  ''',
  directives: [RootComponent],
)
class RootTestComponent implements OnInit {
  @override
  void ngOnInit() => JSInjector.injectGoogleJS();
}

void main() {
  NgTestBed testBed;
  NgTestFixture<RootTestComponent> fixture;
  RootComponentPageObject rootComponentPO;

  setUp(() async {
    testBed = NgTestBed.forComponent<RootTestComponent>(
        ng.RootTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    rootComponentPO = RootComponentPageObject.create(context);
  });

  tearDown(disposeAnyRunningTest);

  test('default title is Display & Video 360', () async {
    expect(rootComponentPO.title, 'Display & Video 360');
  });
}
