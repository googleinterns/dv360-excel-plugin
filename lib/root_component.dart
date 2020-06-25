import 'package:angular/angular.dart';

import 'src/query_component.dart';
import 'src/credential_component.dart';

@Component(
  selector: 'application-root',
  templateUrl: 'root_component.html',
  directives: [CredentialComponent, QueryComponent],
)
class RootComponent {
  final title = 'Display & Video 360';
}
