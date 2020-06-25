@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/credential_component.dart';
import 'package:dv360_excel_plugin/src/credential_service.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'testing/credential_component_po.dart';
import 'credential_component_test.template.dart' as ng;

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
  selector: 'credential-test-component',
  template: '<credential override></credential>',
  directives: [
    CredentialComponent,
    OverrideDirective,
  ],
)
class CredentialTestComponent {}

void main() {
  NgTestBed testBed;
  NgTestFixture<CredentialTestComponent> fixture;
  CredentialComponentPageObject credentialComponentPO;
  MockCredentialService mockCredential;

  setUp(() async {
    testBed = NgTestBed.forComponent<CredentialTestComponent>(
        ng.CredentialTestComponentNgFactory);
    fixture = await testBed.create();
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    credentialComponentPO = CredentialComponentPageObject.create(context);
    mockCredential = MockCredentialService();
  });

  tearDown(disposeAnyRunningTest);

  test('credential test component invokes handleClientLoad() on init', () {
    verify(mockCredential.handleClientLoad());
  });

  test('sign-on button click invokes handleAuthClick()', () async {
    await credentialComponentPO.clickSignOn();
    verify(mockCredential.handleAuthClick());
  });
}
