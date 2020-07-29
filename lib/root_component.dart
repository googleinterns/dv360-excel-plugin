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
  final signOnButtonName = 'GET STARTED';
  final signOutButtonName = 'Sign out';

  // The current sign-in status.
  bool isUserValidated;

  // The current environment status.
  bool isExcelEnvironment;

  final CredentialService _credential;
  final ExcelDart _excelDart;

  RootComponent(this._credential, this._excelDart);

  @override
  void ngOnInit() async {
    await _credential.handleClientLoad();
    isUserValidated = await _credential.initClient();
    isExcelEnvironment = await _excelDart.loadOffice();
  }

  void onClick() async => isUserValidated = await _credential.handleAuthClick();
}
