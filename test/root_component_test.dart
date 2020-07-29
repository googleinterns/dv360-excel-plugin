@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/root_component.dart';
import 'package:dv360_excel_plugin/src/credential_service.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'root_component_test.template.dart' as ng;
import 'testing/root_component_po.dart';

@Injectable()
class MockCredentialService extends Mock implements CredentialService {
  MockCredentialService._private();

  static final MockCredentialService _singleton =
      MockCredentialService._private();

  factory MockCredentialService() {
    return _singleton;
  }
}

@Directive(
  selector: '[override]',
  providers: [
    ClassProvider(CredentialService, useClass: MockCredentialService),
  ],
)
class OverrideDirective {}

@Component(
  selector: 'root-test-component',
  template: '<application-root override></application-root>',
  directives: [
    RootComponent,
    OverrideDirective,
  ],
)
class RootTestComponent {}

void main() {
  NgTestBed testBed;
  NgTestFixture<RootTestComponent> fixture;
  RootComponentPageObject rootComponentPO;
  MockCredentialService mockCredential;

  setUp(() async {
    testBed = NgTestBed.forComponent<RootTestComponent>(
        ng.RootTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    rootComponentPO = RootComponentPageObject.create(context);
    mockCredential = MockCredentialService();
  });

  tearDown(disposeAnyRunningTest);

  test('root test component invokes handleClientLoad() on init', () {
    verify(mockCredential.validateUser());
  });

  test('sign-on button click invokes handleAuthClick()', () async {
    await rootComponentPO.clickSignOn();
    verify(mockCredential.handleAuthClick());
  });

  test('sign-off button click invokes handleAuthClick()', () async {
    await rootComponentPO.clickSignOff();
    verify(mockCredential.handleAuthClick());
  });
}
