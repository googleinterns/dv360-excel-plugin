import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:fixnum/fixnum.dart';
import 'package:ng_bootstrap/ng_bootstrap.dart';
import 'package:recase/recase.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';

import 'data_model/rule.pb.dart';
import 'service/credential_service.dart';
import 'service/rule_service.dart';

enum RepeatingScheduleType {
  everyYear,
  everyMonth,
  everyDay,
  everyHour,
  everyMinute
}

@Component(
  selector: 'rule-creator',
  templateUrl: 'rule_creator_component.html',
  directives: [coreDirectives, formDirectives, BsInput, bsAccordionDirectives],
  providers: [ClassProvider(RuleService)],
)
class RuleCreatorComponent {
  final RuleService _ruleService;
  final CredentialService _credentialService;

  // Stores and retrieves the ID token from local storage.
  // TODO(@thu5): Use HttpOnly cookies instead of local storage.
  String get idToken => window.localStorage['idToken'];
  set idToken(String value) => window.localStorage['idToken'] = value;
  bool get hasIdToken => window.localStorage.containsKey('idToken');

  // Rule details and scope input.
  String name;
  String actionType;
  String lineItemIds;
  String advertiserId;

  // Line item status change input.
  String status;

  // Schedule input.
  String timezone;
  String scheduleType;
  String freq;
  String year, month, day, hour, minute;

  // Condition input.
  String conditionType;
  String relation;
  String value;

  // User interface.
  bool isSuccess;
  bool isAlertVisible = false;
  bool firstPanelOpen = true;

  // Maps from UI name to actual values.
  Map<String, Action_Type> actionTypes = {
    for (var element in Action_Type.values.sublist(1))
      element.name.sentenceCase: element
  };
  Map<String, ChangeLineItemStatusParams_Status> statusTypes = {
    for (var element in ChangeLineItemStatusParams_Status.values.sublist(1))
      element.name.sentenceCase: element
  };
  Map<String, Schedule_Type> scheduleTypes = {
    for (var element in Schedule_Type.values.sublist(1))
      element.name.sentenceCase: element
  };
  Map<String, int> freqTypes = {
    for (var element in RepeatingScheduleType.values)
      element.toString().split('.').last.sentenceCase: element.index
  };
  Map<String, Condition_Type> conditionTypes = {
    for (var element in Condition_Type.values.sublist(1)) element.name: element
  };
  Map<String, Condition_Relation> relationTypes = {
    '<=': Condition_Relation.LESSER_EQUAL,
    '>': Condition_Relation.GREATER
  };

  List<String> timezones = [];

  RuleCreatorComponent(this._ruleService, this._credentialService) {
    initializeTimeZones();
    timeZoneDatabase.locations.keys.forEach((e) => timezones.add(e));
  }

  // TODO(@thu5): Move user creation logic outside this component.
  Future<void> createUser() async {
    final tokens = await _credentialService.obtainTokens();
    final refreshToken = tokens['refresh_token'];
    idToken = tokens['id_token'];

    await _ruleService.createUser(idToken, refreshToken);
  }

  Future<void> onSubmit() async {
    final rule = Rule()..name = name;

    // Sets the action and scope parameters depending on the action type.
    switch (actionTypes[actionType]) {
      case Action_Type.CHANGE_LINE_ITEM_STATUS:
        rule.action = (Action()
          ..type = actionTypes[actionType]
          ..changeLineItemStatusParams =
              (ChangeLineItemStatusParams()..status = statusTypes[status]));
        rule.scope = Scope()
          ..lineItemScopeParams = (LineItemScopeParams()
            ..lineItemIds.addAll(
                lineItemIds.replaceAll(' ', '').split(',').map(Int64.parseInt))
            ..advertiserId = Int64.parseInt(advertiserId));
        break;
      default:
        throw Exception('Not a valid action type');
    }

    // Sets the schedule parameters.
    switch (scheduleTypes[scheduleType]) {
      case Schedule_Type.REPEATING:
        rule.schedule = Schedule()
          ..type = scheduleTypes[scheduleType]
          ..timezone = timezone
          ..repeatingParams = (Schedule_RepeatingParams()
            ..cronExpression = _cronExpression(month, day, hour, minute));
        break;
      default:
        throw Exception('Not a valid schedule type');
    }

    // Sets the condition parameters if set.
    if (conditionTypes[conditionType] != Condition_Type.UNSPECIFIED_TYPE) {
      rule.condition = Condition()
        ..type = conditionTypes[conditionType]
        ..relation = relationTypes[relation]
        ..value = double.parse(value);
    }

    isSuccess = await _ruleService.createRule(idToken, rule) == 200;

    _clearForm();
  }

  String _cronExpression(String month, String day, String hour, String minute) {
    final expression = <String>[];
    expression.add(freqTypes[freq] <= freqTypes['Every hour'] ? minute : '*');
    expression.add(freqTypes[freq] <= freqTypes['Every day'] ? hour : '*');
    expression.add(freqTypes[freq] <= freqTypes['Every month'] ? day : '*');
    expression.add(freqTypes[freq] <= freqTypes['Every year'] ? month : '*');
    expression.add('*');
    return expression.join(' ');
  }

  void _clearForm() {
    firstPanelOpen = true;
    isAlertVisible = true;
    name = actionType = lineItemIds = advertiserId = null;
    status = null;
    timezone = scheduleType = freq = year = month = day = hour = minute = null;
    relation = value = conditionType = null;
  }
}
