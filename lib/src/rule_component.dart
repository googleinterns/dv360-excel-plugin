import 'dart:html';

import 'package:angular/angular.dart';
import 'package:dv360_excel_plugin/src/service/rule_service.dart';

import 'data_model/rule.pb.dart';
import 'rule_creator_component.dart';
import 'rule_detail_component.dart';
import 'rule_list_component.dart';
import 'service/credential_service.dart';

enum View {
  listView,
  createView,
  detailView,
}

@Component(
  selector: 'rule',
  templateUrl: 'rule_component.html',
  directives: [
    coreDirectives,
    RuleListComponent,
    RuleCreatorComponent,
    RuleDetailComponent,
  ],
  exports: [View],
  providers: [ClassProvider(RuleService), ClassProvider(CredentialService)],
)
class RuleComponent {
  final CredentialService _credentialService;
  final RuleService _ruleService;

  View view = View.listView;
  Rule detailedRule;

  // Stores and retrieves the ID token from session storage.
  String get idToken => window.sessionStorage['idToken'];
  set idToken(String value) => window.sessionStorage['idToken'] = value;
  bool get hasIdToken => window.sessionStorage.containsKey('idToken');

  RuleComponent(this._credentialService, this._ruleService);

  void toCreateView() {
    view = View.createView;
  }

  void toListView() {
    view = View.listView;
  }

  void toDetailView() {
    view = View.detailView;
  }

  Future<void> changeDetailedRule(Rule rule) async {
    detailedRule = rule;
    toDetailView();
  }

  Future<void> createUser() async {
    final tokens = await _credentialService.obtainTokens();
    final refreshToken = tokens['refresh_token'];
    idToken = tokens['id_token'];

    await _ruleService.createUser(idToken, refreshToken);
  }
}
