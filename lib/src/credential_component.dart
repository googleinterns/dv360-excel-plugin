import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';

import 'credential_service.dart';

@Component(
  selector: 'credential',
  template: '''
    <material-button (click)="onClick()" debugId="sign-on-btn">
    {{buttonName}}
    </material-button>
  ''',
  providers: [ClassProvider(CredentialService)],
  directives: [MaterialButtonComponent],
)
class CredentialComponent implements OnInit {
  final buttonName = 'sign on';
  final CredentialService _credential;

  CredentialComponent(this._credential);

  @override
  void ngOnInit() {
    _credential.handleClientLoad();
  }

  void onClick() => _credential.handleAuthClick();
}
