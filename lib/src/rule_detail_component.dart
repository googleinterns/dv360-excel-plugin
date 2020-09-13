import 'dart:html';

import 'package:angular/angular.dart';
import 'package:recase/recase.dart';

import 'data_model/get_run_history.pb.dart';
import 'data_model/rule.pb.dart';
import 'javascript_api/schedule_parser.dart';
import 'service/rule_service.dart';

@Component(
  selector: 'rule-detail',
  templateUrl: 'rule_detail_component.html',
  directives: [coreDirectives],
  providers: [ClassProvider(ScheduleParser), ClassProvider(RuleService)],
)
class RuleDetailComponent implements AfterChanges {
  String get idToken => window.localStorage['idToken'];
  set idToken(String value) => window.localStorage['idToken'] = value;
  bool get hasIdToken => window.localStorage.containsKey('idToken');

  // Maps from actual values to UI name.
  Map<Action_Type, String> actionTypes = {
    for (var element in Action_Type.values.sublist(1))
      element: element.name.sentenceCase
  };
  Map<ChangeLineItemStatusParams_Status, String> statusTypes = {
    for (var element in ChangeLineItemStatusParams_Status.values.sublist(1))
      element: element.name.sentenceCase
  };
  Map<Schedule_Type, String> scheduleTypes = {
    for (var element in Schedule_Type.values.sublist(1))
      element: element.name.sentenceCase
  };
  Map<Condition_Type, String> conditionTypes = {
    for (var element in Condition_Type.values.sublist(1))
      element: element.name.sentenceCase
  };
  Map<Condition_Relation, String> relationTypes = {
    Condition_Relation.LESSER_EQUAL: '<=',
    Condition_Relation.GREATER: '>',
  };

  @Input()
  Rule rule;

  final ScheduleParser scheduleParser;
  final RuleService _ruleService;
  final List<Rule> rules = [];
  final List<RunEntry> runHistory = [];

  RuleDetailComponent(this.scheduleParser, this._ruleService);

  List<String> getScopeParameterStrings(Scope scope) {
    switch (scope.type) {
      case Scope_Type.LINE_ITEM_TYPE:
        final lineItems =
            'For line item IDs: ${scope.lineItemScopeParams.lineItemIds.join(', ')}';
        final advertiser =
            'With advertiser ID: ${scope.lineItemScopeParams.advertiserId}';
        return [lineItems, advertiser];
      default:
        return [''];
    }
  }

  String getActionParameterString(Action action) {
    switch (action.type) {
      case Action_Type.CHANGE_LINE_ITEM_STATUS:
        final status =
            action.changeLineItemStatusParams.status.toString().toLowerCase();
        return 'To $status';
      default:
        return '';
    }
  }

  String getConditionParameterString(Condition condition) {
    switch (condition.type) {
      case Condition_Type.CPM:
        return 'If CPM ${relationTypes[condition.relation]} ${condition.value}';
      default:
        return '';
    }
  }

  String getFormattedTimestamp(timestamp) {
    return DateTime.parse(timestamp).toLocal().toString();
  }

  @override
  void ngAfterChanges() async {
    runHistory.clear();
    runHistory
        .addAll((await _ruleService.getRunHistory(idToken, rule.id)).history);
  }
}
