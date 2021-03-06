import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:fixnum/fixnum.dart';
import 'package:ng_bootstrap/ng_bootstrap.dart';
import 'package:recase/recase.dart';
import 'package:proto/rule.pb.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart';

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
  providers: [ClassProvider(RuleService), ClassProvider(CredentialService)],
)
class RuleCreatorComponent {
  final RuleService _ruleService;
  final CredentialService _credentialService;

  // Stores and retrieves the ID token from session storage.
  String get idToken => window.sessionStorage['idToken'];
  set idToken(String value) => window.sessionStorage['idToken'] = value;
  bool get hasIdToken => window.sessionStorage.containsKey('idToken');

  // Rule details and scope input.
  String name;
  String actionType;
  String lineItemIds;
  String advertiserId;

  // Line item status change input.
  String status;

  // Line item bidding strategy change input.
  String biddingStrategy;
  String bidAmount;
  String performanceGoal;
  String goalAmount;

  // Schedule input.
  String timezone;
  String scheduleType;
  String freq;
  String year, month, day, hour, minute;

  // Duplicate line item input.
  String advertiserIdDestination;
  String insertionOrderIdDestination;

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
  Map<String, ChangeLineItemBiddingStrategyParams_BiddingStrategy>
      strategyTypes = {
    for (var element in ChangeLineItemBiddingStrategyParams_BiddingStrategy
        .values
        .sublist(1))
      element.name.sentenceCase: element
  };
  Map<String, BiddingStrategyPerformanceGoalType> performanceGoalTypes = {
    'CPA': BiddingStrategyPerformanceGoalType.CPA,
    'CPC': BiddingStrategyPerformanceGoalType.CPC,
    'Viewable impressions':
        BiddingStrategyPerformanceGoalType.VIEWABLE_IMPRESSIONS,
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
    '≤': Condition_Relation.LESSER_EQUAL,
    '>': Condition_Relation.GREATER
  };

  List<String> timezones = [];

  RuleCreatorComponent(this._ruleService, this._credentialService) {
    initializeTimeZones();
    timeZoneDatabase.locations.keys.forEach((e) => timezones.add(e));
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
          ..type = Scope_Type.LINE_ITEM_TYPE
          ..lineItemScopeParams = (LineItemScopeParams()
            ..lineItemIds.addAll(
                lineItemIds.replaceAll(' ', '').split(',').map(Int64.parseInt))
            ..advertiserId = Int64.parseInt(advertiserId));
        break;
      case Action_Type.DUPLICATE_LINE_ITEM:
        rule.action = (Action()
          ..type = actionTypes[actionType]
          ..duplicateLineItemParams = (DuplicateLineItemParams()
            ..advertiserId = Int64.parseInt(advertiserIdDestination)
            ..insertionOrderId = Int64.parseInt(insertionOrderIdDestination)));
        break;
      case Action_Type.CHANGE_LINE_ITEM_BIDDING_STRATEGY:
        rule.action = (Action()..type = actionTypes[actionType]);
        rule.scope = Scope()
          ..type = Scope_Type.LINE_ITEM_TYPE
          ..lineItemScopeParams = (LineItemScopeParams()
            ..lineItemIds.addAll(
                lineItemIds.replaceAll(' ', '').split(',').map(Int64.parseInt))
            ..advertiserId = Int64.parseInt(advertiserId));
        switch (strategyTypes[biddingStrategy]) {
          case ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED:
            rule.action.changeLineItemBiddingStrategyParams =
                ChangeLineItemBiddingStrategyParams()
                  ..biddingStrategy =
                      ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED
                  ..fixedBidStrategyParams = (FixedBidStrategyParams()
                    ..bidAmountMicros = Int64(
                        ((double.parse(bidAmount) * pow(10, 6)).toInt())));
            break;
          case ChangeLineItemBiddingStrategyParams_BiddingStrategy
              .MAXIMIZE_SPEND:
            rule.action.changeLineItemBiddingStrategyParams =
                ChangeLineItemBiddingStrategyParams()
                  ..biddingStrategy =
                      ChangeLineItemBiddingStrategyParams_BiddingStrategy
                          .MAXIMIZE_SPEND
                  ..maximizeSpendBidStrategyParams =
                      (MaximizeSpendBidStrategyParams()
                        ..type = performanceGoalTypes[performanceGoal]);
            break;
          case ChangeLineItemBiddingStrategyParams_BiddingStrategy
              .PERFORMANCE_GOAL:
            rule.action.changeLineItemBiddingStrategyParams =
                ChangeLineItemBiddingStrategyParams()
                  ..biddingStrategy =
                      ChangeLineItemBiddingStrategyParams_BiddingStrategy
                          .PERFORMANCE_GOAL
                  ..performanceGoalBidStrategyParams =
                      (PerformanceGoalBidStrategyParams()
                        ..type = performanceGoalTypes[performanceGoal]
                        ..performanceGoalAmountMicros = Int64(
                            (double.parse(goalAmount) * pow(10, 6)).toInt()));
            break;
          default:
            throw Exception('Not a valid bidding strategy type');
        }
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
            ..cronExpression =
                _repeatingCronExpression(month, day, hour, minute));
        break;
      case Schedule_Type.ONE_TIME:
        rule.schedule = Schedule()
          ..type = scheduleTypes[scheduleType]
          ..timezone = timezone
          ..oneTimeParams = (Schedule_OneTimeParams()
            ..cronExpression = '$minute $hour $day $month *'
            ..year = int.parse(year));
        break;
      default:
        throw Exception('Not a valid schedule type');
    }

    // Sets the condition parameters if set.
    if (conditionTypes[conditionType] != null) {
      rule.condition = Condition()
        ..type = conditionTypes[conditionType]
        ..relation = relationTypes[relation]
        ..value = double.parse(value);
    }

    isSuccess = await _ruleService.createRule(idToken, rule) == 200;

    _clearForm();
  }

  String _repeatingCronExpression(
      String month, String day, String hour, String minute) {
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
    advertiserIdDestination = insertionOrderIdDestination = null;
    biddingStrategy = bidAmount = performanceGoal = goalAmount = null;
    timezone = scheduleType = freq = year = month = day = hour = minute = null;
    relation = value = conditionType = null;
  }
}
