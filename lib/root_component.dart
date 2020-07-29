import 'package:angular/angular.dart';
import 'package:ng_bootstrap/ng_bootstrap.dart';

import 'src/credential_service.dart';
import 'src/excel.dart';
import 'src/query_component.dart';

@Component(
  selector: 'application-root',
  templateUrl: 'root_component.html',
  directives: [bsTabsxDirectives, coreDirectives, QueryComponent],
  providers: [ClassProvider(CredentialService), ClassProvider(ExcelDart)],
)
class RootComponent implements OnInit {
  // Names used in html.
  final title = 'Display & Video 360';
  final welcomeTitle = 'Welcome!';
  final welcomeMessage =
      'Discover what DV360 Excel Add-in can do for you today';
  final sideloadMessage = 'Please sideload the add-in to continue';
  final queryBuilderTabName = 'Query Builder';
  final rulesBuilderTabName = 'Rules Builder';
  final signOnButtonName = 'Get started';
  final signOutButtonName = 'Sign out';

  // The current sign-in status.
  bool _isUserValidated;

  // The current environment status.
  bool _isExcelEnvironment;

  // Controls when to show landing page.
  bool showLandingPage = false;

  // Controls when to show main page.
  bool showMainPage = false;

  // Controls when to the show the sideload message in landing page.
  bool showSideloadMessage = false;

  final CredentialService _credential;
  final ExcelDart _excelDart;

  RootComponent(this._credential, this._excelDart);

  @override
  void ngOnInit() async {
    await _credential.handleClientLoad();
    _isUserValidated = await _credential.initClient();
    _isExcelEnvironment = await _excelDart.loadOffice();
    _updatePage();
  }

  void onClick() async {
    _isUserValidated = await _credential.handleAuthClick();
    _updatePage();
  }

  void _updatePage() {
    showLandingPage = !_isExcelEnvironment || !_isUserValidated;
    showSideloadMessage = !_isExcelEnvironment;
    showMainPage = !showLandingPage;
  }
}
