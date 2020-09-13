import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:googleapis/displayvideo/v1.dart';
import 'package:http/http.dart';

import '../model/action.dart';
import '../model/change_line_item_bidding_strategy_action.dart';
import '../model/change_line_item_status_action.dart';
import '../model/duplicate_line_item_action.dart';
import '../model/rule.dart';
import '../model/scope.dart';
import '../proto/rule.pb.dart' as proto;
import '../service/firestore.dart';

/// A class that wraps around Display & Video 360.
class DisplayVideo360Client {
  /// The DV360 API.
  final DisplayvideoApi _api;

  /// The Firestore client.
  final FirestoreClient _firestoreClient;

  /// Creates an instance of [DisplayVideo360Client].
  DisplayVideo360Client(Client client, this._firestoreClient, String baseUrl)
      : _api = DisplayvideoApi(client, rootUrl: baseUrl);

  /// Changes the entity status of the line item to [status].
  ///
  /// [status] can be "ENTITY_STATUS_ACTIVE" or "ENTITY_STATUS_PAUSED".
  /// Throws an [ApiRequestError] if API returns an error.
  Future<void> changeLineItemStatus(
      Int64 advertiserId, Int64 lineItemId, String status) async {
    final request = LineItem()..entityStatus = status;
    await _api.advertisers.lineItems.patch(
        request, advertiserId.toString(), lineItemId.toString(),
        updateMask: 'entityStatus');
  }

  /// Duplicates the line item to [insertionOrderIdDestination].
  ///
  /// The [advertiserIdDestination] is the ID of the destination advertiser.
  ///
  /// Throws an [ApiRequestError] if API returns an error.
  Future<void> duplicateLineItem(Int64 advertiserId, Int64 lineItemId,
      Int64 advertiserIdDestination, Int64 insertionOrderIdDestination) async {
    final source = await _api.advertisers.lineItems
        .get(advertiserId.toString(), lineItemId.toString());

    // Stores the current entity status because only ENTITY_STATUS_DRAFT is
    // allowed at creation.
    final currentStatus = source.entityStatus;

    // Sets the correct fields for line item creation.
    // Inherits flight dates from the destination parent insertion order.
    source
      ..insertionOrderId = insertionOrderIdDestination.toString()
      ..entityStatus = 'ENTITY_STATUS_DRAFT'
      ..advertiserId = null
      ..campaignId = null
      ..lineItemId = null
      ..updateTime = null
      ..partnerCosts = null
      ..name = null;

    // Creates a duplicate of the line item at destination.
    final duplicate = await _api.advertisers.lineItems
        .create(source, advertiserIdDestination.toString());

    // Matches the new line item's current status to the old status.
    await changeLineItemStatus(Int64.parseInt(duplicate.advertiserId),
        Int64.parseInt(duplicate.lineItemId), currentStatus);
  }

  /// Changes the bidding strategy of the line item to [strategy].
  ///
  /// Throws an [ApiRequestError] if API returns an error.
  Future<void> changeLineItemBiddingStrategy(
      Int64 advertiserId, Int64 lineItemId, String strategy,
      {Int64 bidAmount, String goal, Int64 goalAmount}) async {
    final request = LineItem()..bidStrategy = BiddingStrategy();
    switch (strategy) {
      case 'FIXED':
        request.bidStrategy.fixedBid =
            (FixedBidStrategy()..bidAmountMicros = bidAmount.toString());
        break;
      case 'MAXIMIZE_SPEND':
        request.bidStrategy.maximizeSpendAutoBid =
            (MaximizeSpendBidStrategy()..performanceGoalType = goal);
        break;
      case 'PERFORMANCE_GOAL':
        request.bidStrategy.performanceGoalAutoBid =
            (PerformanceGoalBidStrategy()
              ..performanceGoalType = goal
              ..performanceGoalAmountMicros = goalAmount.toString());
        break;
      default:
        throw UnsupportedError('$strategy is not a supported strategy.');
    }
    await _api.advertisers.lineItems.patch(
        request, advertiserId.toString(), lineItemId.toString(),
        updateMask: 'bidStrategy');
  }

  /// Runs the rule to manipulate DV360 line items and logs the result.
  Future<void> run(Rule rule, String userId, String ruleId) async {
    // If the rule is one-time and the year doesn't match, do not run the rule.
    // Cloud Scheduler uses cron expressions that do not specify the year.
    if (!rule.isRepeating && rule.year != DateTime.now().year) {
      return;
    }

    for (final target in rule.scope.targets) {
      try {
        if (await rule.condition.isTrue(target)) {
          switch (rule.action.runtimeType) {
            case ChangeLineItemStatusAction:
              await runStatusAction(rule.action, target);
              break;
            case DuplicateLineItemAction:
              await runDuplicateAction(rule.action, target);
              break;
            case ChangeLineItemBiddingStrategyAction:
              await runBiddingStrategyAction(rule.action, target);
              break;
            default:
              throw UnsupportedError(
                  '${rule.action.runtimeType} is an invalid action runtime type.');
          }
        }
      } on ApiRequestError catch (e) {
        // If there is an API error, return the message returned by the API.
        return await _firestoreClient.logRunHistory(userId, ruleId, false,
            message: e.message);
      } catch (e) {
        // If there is another kind of exception, do not include the message.
        //
        // The messages we log should be user-friendly, actionable and
        // understandable. We can expect this for DV360 API error messages, but
        // probably not for lower level exception messages. Also, there might be
        // security issues if we directly report the raw exception messages.
        return await _firestoreClient.logRunHistory(userId, ruleId, false,
            message: 'Internal error encountered');
      }
      // Logs the successful run of the rule.
      await _firestoreClient.logRunHistory(userId, ruleId, true);
    }
  }

  /// Changes the status of the line item.
  Future<void> runStatusAction(Action action, Target target) async {
    final lineItemTarget = target as LineItemTarget;
    final changeStatusAction = action as ChangeLineItemStatusAction;

    final shortStatusName = proto.ChangeLineItemStatusParams_Status.valueOf(
        changeStatusAction.statusValue.index);
    final status = 'ENTITY_STATUS_${shortStatusName.name}';

    await changeLineItemStatus(
        lineItemTarget.advertiserId, lineItemTarget.lineItemId, status);
  }

  /// Duplicates the line items using the DV360 client.
  Future<void> runDuplicateAction(Action action, Target target) async {
    final lineItemTarget = target as LineItemTarget;
    final duplicateAction = action as DuplicateLineItemAction;

    await duplicateLineItem(
        lineItemTarget.advertiserId,
        lineItemTarget.lineItemId,
        duplicateAction.advertiserId,
        duplicateAction.insertionOrderId);
  }

  /// Changes the bidding strategy of the line item.
  Future<void> runBiddingStrategyAction(Action action, Target target) async {
    final lineItemTarget = target as LineItemTarget;
    final changeStrategyAction = action as ChangeLineItemBiddingStrategyAction;
    String goal;
    String strategy;

    switch (changeStrategyAction.biddingStrategy) {
      case BidStrategyType.fixed:
        strategy = 'FIXED';
        break;
      case BidStrategyType.maximizeSpend:
        strategy = 'MAXIMIZE_SPEND';
        break;
      case BidStrategyType.performanceGoal:
        strategy = 'PERFORMANCE_GOAL';
        break;
      default:
        throw UnsupportedError('${changeStrategyAction.biddingStrategy} is an '
            'invalid bidding strategy.');
    }

    if (changeStrategyAction.biddingStrategy != BidStrategyType.fixed) {
      // If the bidding strategy is maximize spend, performance goal, or
      // unspecified.
      switch (changeStrategyAction.performanceGoal) {
        case PerformanceGoalType.cpa:
          goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA';
          break;
        case PerformanceGoalType.cpc:
          goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC';
          break;
        case PerformanceGoalType.viewableImpressions:
          if (changeStrategyAction.biddingStrategy ==
              BidStrategyType.maximizeSpend) {
            goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_AV_VIEWED';
          }
          if (changeStrategyAction.biddingStrategy ==
              BidStrategyType.performanceGoal) {
            goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM';
          }
          break;
        default:
          throw UnsupportedError(
              '${changeStrategyAction.performanceGoal} is an '
              'invalid performance goal.');
      }
    }

    await changeLineItemBiddingStrategy(
        lineItemTarget.advertiserId, lineItemTarget.lineItemId, strategy,
        bidAmount: changeStrategyAction.bidAmount,
        goal: goal,
        goalAmount: changeStrategyAction.goalAmount);
  }
}
