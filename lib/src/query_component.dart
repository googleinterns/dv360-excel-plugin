import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';

import 'query_service.dart';

@Component(
  selector: 'query',
  template: '''
    <material-button (click)="onClick()">{{buttonName}}</material-button>
  ''',
  directives: [MaterialButtonComponent],
)

class QueryComponent {
  final buttonName = 'populate';
  final _excelSingular = Excel();
  Excel get _excel => _excelSingular;

  void onClick() {
    _excel.exec();
  }
}