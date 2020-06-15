import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';

import 'excel.dart';

@Component(
  selector: 'query',
  template: '''
    <material-button (click)="onClick()">{{buttonName}}</material-button>
  ''',
  directives: [MaterialButtonComponent],
)
class QueryComponent {
  final buttonName = 'populate';
  final _excel = ExcelDart();

  void onClick() {
    _excel.exec();
  }
}
