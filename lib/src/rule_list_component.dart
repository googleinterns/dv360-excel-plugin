import 'dart:html';

import 'package:angular/angular.dart';
import 'package:proto/rule.pb.dart';
import 'package:recase/recase.dart';

import 'javascript_api/schedule_parser.dart';
import 'service/rule_service.dart';

@Component(
  selector: 'rule-list',
  templateUrl: 'rule_list_component.html',
  directives: [coreDirectives],
  providers: [ClassProvider(RuleService), ClassProvider(ScheduleParser)],
)
class RuleListComponent implements OnInit {
  final ScheduleParser scheduleParser;
  final RuleService _ruleService;
  final List<Rule> rules = [];

  String get idToken => window.localStorage['idToken'];
  set idToken(String value) => window.localStorage['idToken'] = value;
  bool get hasIdToken => window.localStorage.containsKey('idToken');

  Map<Action_Type, String> actionTypes = {
    for (var element in Action_Type.values.sublist(1))
      element: element.name.sentenceCase
  };

  RuleListComponent(this._ruleService, this.scheduleParser);

  @override
  void ngOnInit() async {
    rules.addAll(await _ruleService.getRules(idToken));
  }
}
