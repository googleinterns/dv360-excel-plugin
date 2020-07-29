import 'dart:async';

@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/root_component.dart';
import 'package:dv360_excel_plugin/src/credential_service.dart';
import 'package:dv360_excel_plugin/src/excel.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:pageloader/testing.dart';
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
    ClassProvider(CredentialService, useClass: MockCredentialService),
    Provider(ExcelDart, useClass: MockExcelDart)
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
  group('In $RootComponent,', () {
    NgTestBed testBed;
    NgTestFixture<RootTestComponent> fixture;
    RootComponentLandingPagePageObject rootComponentLandingPagePO;
    RootComponentMainPagePageObject rootComponentMainPagePO;

    MockCredentialService mockCredential;
    MockExcelDart mockExcelDart;

    Completer<bool> credentialCompleter;
    Completer<bool> excelCompleter;
    Completer<bool> buttonCompleter;

    setUp(() async {
      testBed = NgTestBed.forComponent<RootTestComponent>(
          ng.RootTestComponentNgFactory);
      mockCredential = MockCredentialService();
      mockExcelDart = MockExcelDart();
      credentialCompleter = Completer<bool>();
      excelCompleter = Completer<bool>();
      buttonCompleter = Completer<bool>();
    });

    tearDown(disposeAnyRunningTest);

    test(
        'handleClientLoad(), initClient() and loadOffice()'
        'are invoked during init', () async {
      fixture = await testBed.create();

      verify(mockCredential.handleClientLoad());
      verify(mockCredential.initClient());
      verify(mockExcelDart.loadOffice());
    });

    group('when app is not running in excel and user is not validated,', () {
      setUp(() async {
        when(mockCredential.initClient())
            .thenAnswer((_) => credentialCompleter.future);
        when(mockExcelDart.loadOffice())
            .thenAnswer((_) => excelCompleter.future);

        fixture = await testBed.create();

        final context =
            HtmlPageLoaderElement.createFromElement((fixture.rootElement));
        rootComponentLandingPagePO =
            RootComponentLandingPagePageObject.create(context);
        rootComponentMainPagePO =
            RootComponentMainPagePageObject.create(context);

        await fixture.update((_) {
          credentialCompleter.complete(false);
          excelCompleter.complete(false);
        });
      });

      test('landing page is displayed', () async {
        expect(rootComponentLandingPagePO.landingPage, exists);
      });

      test('sideload message is displayed', () async {
        expect(rootComponentLandingPagePO.sideloadMessage, exists);
      });

      test('welcome message is removed', () async {
        expect(rootComponentLandingPagePO.welcomeMessage, notExists);
      });

      test('sign-on button is removed', () async {
        expect(rootComponentLandingPagePO.signOnButton, notExists);
      });

      test('main page is removed', () async {
        expect(rootComponentMainPagePO.mainPage, notExists);
      });
    });

    group('when app is running in excel and user is not validated,', () {
      setUp(() async {
        when(mockCredential.initClient())
            .thenAnswer((_) => credentialCompleter.future);
        when(mockExcelDart.loadOffice())
            .thenAnswer((_) => excelCompleter.future);

        fixture = await testBed.create();

        final context =
            HtmlPageLoaderElement.createFromElement((fixture.rootElement));
        rootComponentLandingPagePO =
            RootComponentLandingPagePageObject.create(context);
        rootComponentMainPagePO =
            RootComponentMainPagePageObject.create(context);

        await fixture.update((_) {
          credentialCompleter.complete(false);
          excelCompleter.complete(true);
        });
      });

      test('landing page is displayed', () async {
        expect(rootComponentLandingPagePO.landingPage, exists);
      });

      test('welcome message is displayed', () async {
        expect(rootComponentLandingPagePO.welcomeMessage, exists);
      });

      test('sign-on button is displayed', () async {
        expect(rootComponentLandingPagePO.signOnButton, exists);
      });

      test('sideload message is removed', () async {
        expect(rootComponentLandingPagePO.sideloadMessage, notExists);
      });

      test('main page is removed', () async {
        expect(rootComponentMainPagePO.mainPage, notExists);
      });
    });

    group('when app is running in excel and user is validated,', () {
      setUp(() async {
        when(mockCredential.initClient())
            .thenAnswer((_) => credentialCompleter.future);
        when(mockExcelDart.loadOffice())
            .thenAnswer((_) => excelCompleter.future);

        fixture = await testBed.create();

        final context =
            HtmlPageLoaderElement.createFromElement((fixture.rootElement));
        rootComponentLandingPagePO =
            RootComponentLandingPagePageObject.create(context);
        rootComponentMainPagePO =
            RootComponentMainPagePageObject.create(context);

        await fixture.update((_) {
          credentialCompleter.complete(true);
          excelCompleter.complete(true);
        });
      });

      test('main page is displayed', () async {
        expect(rootComponentMainPagePO.mainPage, exists);
      });

      test('sign-off button is displayed', () async {
        expect(rootComponentMainPagePO.signOffButton, exists);
      });

      test('landing page is removed', () async {
        expect(rootComponentLandingPagePO.landingPage, notExists);
      });
    });

    group('when landing page is displayed, clicking on the sign-on button', () {
      setUp(() async {
        when(mockCredential.initClient())
            .thenAnswer((_) => credentialCompleter.future);
        when(mockExcelDart.loadOffice())
            .thenAnswer((_) => excelCompleter.future);

        fixture = await testBed.create();

        final context =
            HtmlPageLoaderElement.createFromElement((fixture.rootElement));
        rootComponentLandingPagePO =
            RootComponentLandingPagePageObject.create(context);
        rootComponentMainPagePO =
            RootComponentMainPagePageObject.create(context);

        await fixture.update((_) {
          credentialCompleter.complete(false);
          excelCompleter.complete(true);
        });

        when(mockCredential.handleAuthClick())
            .thenAnswer((_) => buttonCompleter.future);

        await rootComponentLandingPagePO.clickSignOn();
        await fixture.update((_) => buttonCompleter.complete(true));
      });

      test('hides the landing page', () async {
        expect(rootComponentLandingPagePO.landingPage, notExists);
      });

      test('hides the sign-on button', () async {
        expect(rootComponentLandingPagePO.signOnButton, notExists);
      });

      test('displays the main page', () async {
        expect(rootComponentMainPagePO.mainPage, exists);
      });

      test('displays the sign-off button', () async {
        expect(rootComponentMainPagePO.signOffButton, exists);
      });
    });

    group('when main page is displayed, clicking on the sign-off button', () {
      setUp(() async {
        when(mockCredential.initClient())
            .thenAnswer((_) => credentialCompleter.future);
        when(mockExcelDart.loadOffice())
            .thenAnswer((_) => excelCompleter.future);

        fixture = await testBed.create();

        final context =
            HtmlPageLoaderElement.createFromElement((fixture.rootElement));
        rootComponentLandingPagePO =
            RootComponentLandingPagePageObject.create(context);
        rootComponentMainPagePO =
            RootComponentMainPagePageObject.create(context);

        await fixture.update((_) {
          credentialCompleter.complete(true);
          excelCompleter.complete(true);
        });

        when(mockCredential.handleAuthClick())
            .thenAnswer((_) => buttonCompleter.future);

        await rootComponentMainPagePO.clickSignOff();
        await fixture.update((_) => buttonCompleter.complete(false));
      });

      test('hides the main page', () async {
        expect(rootComponentMainPagePO.mainPage, notExists);
      });

      test('hides the sign-off button', () async {
        expect(rootComponentMainPagePO.signOffButton, notExists);
      });

      test('displays the landing page', () async {
        expect(rootComponentLandingPagePO.landingPage, exists);
      });

      test('displays the sign-on button', () async {
        expect(rootComponentLandingPagePO.signOnButton, exists);
      });
    });
  });
}
