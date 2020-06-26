import 'package:angular/angular.dart';

import 'credential_service.dart';

@Component(
  selector: 'credential',
  template: '''
    <button (click)="onClick()" debugId="sign-on-btn">
    {{buttonName}}
    </button>
  ''',
  providers: [ClassProvider(CredentialService)],
)
class CredentialComponent implements OnInit {
  final buttonName = 'sign on';
  final CredentialService _credential;

  CredentialComponent(this._credential);

  @override
  void ngOnInit() => _credential.handleClientLoad();

  void onClick() => _credential.handleAuthClick();
}
