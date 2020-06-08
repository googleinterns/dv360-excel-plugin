import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:dv360_excel_plugin/src/credential.dart';
import 'package:dv360_excel_plugin/src/excel.dart';

@Component(
  selector: 'my-app',
  templateUrl: 'app_component.html',
  styleUrls: ['app_component.css'],
  directives: [coreDirectives, MaterialButtonComponent],
)

class AppComponent implements OnInit{
  String title = 'Display & Video 360';
  Excel get excel => Excel();
  Credential get credential => Credential();

  @override
  void ngOnInit() {
    credential.handleClientLoad();
  }
}

