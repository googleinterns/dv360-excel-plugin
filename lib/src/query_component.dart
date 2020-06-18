import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';

import 'excel.dart';

@Component(
  selector: 'query',
  template: '''
    <material-button (click)="onClick()" debugId="populate-btn">
    {{buttonName}}
    </material-button>
  ''',
  providers: [ClassProvider(ExcelDart)],
  directives: [MaterialButtonComponent],
)
class QueryComponent {
  final buttonName = 'populate';
  final ExcelDart _excel;

  QueryComponent(this._excel);

  void onClick() => _excel.exec();
}
