import 'package:angular/angular.dart';
import 'package:ng_bootstrap/ng_bootstrap.dart';

import 'src/javascript_api/excel_api.dart';
import 'src/javascript_api/google_api.dart';
import 'src/query_component.dart';
import 'src/rule_component.dart';
import 'src/service/credential_service.dart';

@Component(
  selector: 'application-root',
  templateUrl: 'root_component.html',
  directives: [
    bsTabsxDirectives,
    coreDirectives,
    QueryComponent,
    RuleComponent,
  ],
  providers: [
    ClassProvider(CredentialService),
    ClassProvider(ExcelDart),
    ClassProvider(GoogleApiDart)
  ],
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
  bool get showLandingPage {
    if (_isUserValidated == null || _isExcelEnvironment == null) return false;
    return !_isUserValidated || !_isExcelEnvironment;
  }

  // Controls when to show main page.
  bool get showMainPage {
    if (_isUserValidated == null || _isExcelEnvironment == null) return false;
    return _isUserValidated && _isExcelEnvironment;
  }

  // Controls when to the show the sideload message in landing page.
  bool get showSideloadMessage => !_isExcelEnvironment;

  final CredentialService _credential;
  final ExcelDart _excelDart;

  RootComponent(this._credential, this._excelDart);

  @override
  void ngOnInit() async {
    await _credential.handleClientLoad();
    _isUserValidated = await _credential.initClient();
    _isExcelEnvironment = await _excelDart.loadOffice();
  }

  void onClick() async =>
      _isUserValidated = await _credential.handleAuthClick();
}
