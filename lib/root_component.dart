import 'package:angular/angular.dart';
import 'package:dv360_excel_plugin/src/credential_service.dart';
import 'package:dv360_excel_plugin/src/excel.dart';

import 'src/query_component.dart';
import 'src/credential_component.dart';

@Component(
  selector: 'application-root',
  templateUrl: 'root_component.html',
  providers: [ClassProvider(CredentialService), ClassProvider(ExcelDart)],
  directives: [CredentialComponent, QueryComponent],
)
class RootComponent {
  final title = 'Display & Video 360';
}
