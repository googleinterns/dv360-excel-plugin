@TestOn('browser')

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/credential_component.dart';
import 'package:dv360_excel_plugin/src/credential_service.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:test/test.dart';

import 'credential_component_po.dart';
import 'credential_component_test.template.dart' as ng;
import 'util/js_injector.dart';

class MockCredential extends Mock implements CredentialService {}

@Component(
  selector: 'credential-test-component',
  template: '''
    <credential></credential>
  ''',
  directives: [CredentialComponent],
)
class CredentialTestComponent implements OnInit {
  @override
  void ngOnInit() => JSInjector.injectGoogleJS();
}

@GenerateInjector([
  Provider(CredentialService, useClass: MockCredential),
])
final InjectorFactory injector = ng.injector$Injector;

void main() {
  NgTestBed testBed;
  NgTestFixture<CredentialTestComponent> fixture;
  CredentialComponentPageObject credentialComponentPO;
  MockCredential mockCredential;

  setUp(() async {
    testBed = NgTestBed.forComponent<CredentialTestComponent>(
        ng.CredentialTestComponentNgFactory,
        rootInjector: injector);
    fixture = await testBed.create(
        beforeComponentCreated: (injector) =>
            mockCredential = injector.get(CredentialService));
    final context =
        HtmlPageLoaderElement.createFromElement((fixture.rootElement));
    credentialComponentPO = CredentialComponentPageObject.create(context);
  });

  tearDown(disposeAnyRunningTest);

  test('credential component init invokes handleClientLoad()', () {
    verify(mockCredential.handleClientLoad());
  });

  test('sign-on button click invokes handleAuthClick()', () async {
    await credentialComponentPO.signOn();
    verify(mockCredential.handleAuthClick());
  });
}
