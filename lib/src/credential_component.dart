import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';

import 'credential_service.dart';

@Component(
  selector: 'sign-on',
  template: '''
    <material-button (click)="onClick()">{{buttonName}}</material-button>
  ''',
  directives: [MaterialButtonComponent],
)

class SignOnComponent implements OnInit {
  var buttonName = 'sign on';
  final _credentialSingular = Credential();
  Credential get _credential => _credentialSingular;

  @override
  void ngOnInit() {
    _credential.handleClientLoad();
  }

  void onClick() {
    _credentialSingular.handleAuthClick();
  }
}
