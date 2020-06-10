import 'package:angular/angular.dart';
import 'package:dv360_excel_plugin/src/query_component.dart';
import 'package:dv360_excel_plugin/src/credential_component.dart';

@Component(
  selector: 'application-root',
  templateUrl: 'root_component.html',
  styleUrls: ['root_component.css'],
  directives: [SignOnComponent, QueryComponent],
)

class RootComponent {
  final title = 'Display & Video 360 Hello!';
}