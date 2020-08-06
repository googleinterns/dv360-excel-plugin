import 'dart:async';

@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/root_component.dart';
import 'package:dv360_excel_plugin/src/javascript_api/excel_api.dart';
import 'package:dv360_excel_plugin/src/javascript_api/google_api.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:pageloader/html.dart';
import 'package:pageloader/testing.dart';
import 'package:test/test.dart';

import 'root_component_test.template.dart' as ng;
import 'testing/root_component_po.dart';

@Injectable()
class MockGoogleApiDart extends Mock implements GoogleApiDart {
  MockGoogleApiDart._private();

  static final MockGoogleApiDart _singleton = MockGoogleApiDart._private();

  factory MockGoogleApiDart() {
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
    ClassProvider(ExcelDart, useClass: MockExcelDart),
    ClassProvider(GoogleApiDart, useClass: MockGoogleApiDart),
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
    const apiKey = 'API_KEY';
    const clientId = 'CLIENT_ID';
    const redirectUri = 'http://localhost:8080';
    const scope = 'https://www.googleapis.com/auth/display-video '
        'https://www.googleapis.com/auth/doubleclickbidmanager '
        'https://www.googleapis.com/auth/devstorage.read_only';
    const discoveryDocs = [
      'https://displayvideo.googleapis.com/\$discovery/rest?version=v1',
      'https://content.googleapis.com/discovery/v1/apis/doubleclickbidmanager/v1.1/rest'
    ];

    NgTestBed testBed;
    NgTestFixture<RootTestComponent> fixture;
    RootComponentLandingPagePageObject rootComponentLandingPagePO;
    RootComponentMainPagePageObject rootComponentMainPagePO;

    MockGoogleApiDart mockGoogleApiDart;
    MockExcelDart mockExcelDart;

    Completer<bool> googleApiCompleter;
    Completer<bool> excelCompleter;

    setUp(() async {
      testBed = NgTestBed.forComponent<RootTestComponent>(
          ng.RootTestComponentNgFactory);
      mockGoogleApiDart = MockGoogleApiDart();
      mockExcelDart = MockExcelDart();
      googleApiCompleter = Completer<bool>();
      excelCompleter = Completer<bool>();
    });

    tearDown(disposeAnyRunningTest);

    test(
        'handleClientLoad(), initClient() and loadOffice()'
        'are invoked during init', () async {
      fixture = await testBed.create();

      verify(mockGoogleApiDart.loadLibrary('client:auth2'));
      verify(mockGoogleApiDart.initClient(
          apiKey, clientId, discoveryDocs, scope, any));
      verify(mockExcelDart.loadOffice());
    });

    group('when app is not running in excel and user is not validated,', () {
      setUp(() async {
        when(mockGoogleApiDart.initClient(
                apiKey, clientId, discoveryDocs, scope, any))
            .thenAnswer((_) => googleApiCompleter.future);
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
          googleApiCompleter.complete(false);
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
        when(mockGoogleApiDart.initClient(
                apiKey, clientId, discoveryDocs, scope, any))
            .thenAnswer((_) => googleApiCompleter.future);
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
          googleApiCompleter.complete(false);
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
        when(mockGoogleApiDart.initClient(
                apiKey, clientId, discoveryDocs, scope, any))
            .thenAnswer((_) => googleApiCompleter.future);
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
          googleApiCompleter.complete(true);
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
        when(mockGoogleApiDart.initClient(
                apiKey, clientId, discoveryDocs, scope, any))
            .thenAnswer((_) => googleApiCompleter.future);
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
          googleApiCompleter.complete(false);
          excelCompleter.complete(true);
        });

        when(mockGoogleApiDart.getSignInStatus()).thenReturn(false);
        await rootComponentLandingPagePO.clickSignOn();
        await fixture.update();
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
        when(mockGoogleApiDart.initClient(
                apiKey, clientId, discoveryDocs, scope, any))
            .thenAnswer((_) => googleApiCompleter.future);
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
          googleApiCompleter.complete(true);
          excelCompleter.complete(true);
        });

        when(mockGoogleApiDart.getSignInStatus()).thenReturn(true);
        await rootComponentMainPagePO.clickSignOff();
        await fixture.update();
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
