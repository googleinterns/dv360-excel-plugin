import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:recase/recase.dart';

import 'data_model/rule.pb.dart';
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
  final _detailedRule = StreamController<Rule>();

  // Stores and retrieves the ID token from session storage.
  String get idToken => window.sessionStorage['idToken'];
  set idToken(String value) => window.sessionStorage['idToken'] = value;
  bool get hasIdToken => window.sessionStorage.containsKey('idToken');

  Map<Action_Type, String> actionTypes = {
    for (var element in Action_Type.values.sublist(1))
      element: element.name.sentenceCase
  };

  @Output()
  Stream<Rule> get detailedRule => _detailedRule.stream;

  RuleListComponent(this._ruleService, this.scheduleParser);

  @override
  void ngOnInit() async {
    rules.addAll(await _ruleService.getRules(idToken));
  }

  void addToStream(Rule rule) {
    _detailedRule.add(rule);
  }
}
