import 'dart:async';

import 'package:fixnum/fixnum.dart';

import '../proto/rule.pb.dart' as proto;
import '../service/dv360.dart';
import 'scope.dart';

/// An interface that represents an action to manipulate DV360 entities.
abstract class Action {
  /// Creates an instance of a class that implements [Action], from a proto.
  ///
  /// Throws an [UnsupportedError] if the proto's action type is unspecified.
  static Action getActionFromProto(proto.Action action) {
    switch (action.type) {
      case proto.Action_Type.CHANGE_LINE_ITEM_STATUS:
        return ChangeLineItemStatusAction(action);
      case proto.Action_Type.CHANGE_LINE_ITEM_BIDDING_STRATEGY:
        return ChangeLineItemBiddingStrategyAction(action);
      default:
        throw UnsupportedError(
            '${action.type} is not a supported action type.');
    }
  }

  /// Creates a proto that represents the [Action].
  proto.Action toProto();

  /// Executes the action on [target] using the [client].
  Future<void> run(DisplayVideo360Client client, Target target);
}

/// A class that represents changing the line item status.
///
/// The line item can be activated or paused.
class ChangeLineItemStatusAction implements Action {
  /// The integer value of the target line item status.
  int _statusValue;

  /// Creates a [ChangeLineItemStatusAction] instance from a [proto.Action].
  ChangeLineItemStatusAction(proto.Action action) {
    _statusValue = action.changeLineItemStatusParams.status.value;
  }

  /// Creates a [proto.Action] with Change line Item Status parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
        ..status =
            proto.ChangeLineItemStatusParams_Status.valueOf(_statusValue));
  }

  /// Changes the status of the line item using the DV360 client.
  /// TODO(@thu5): Record the return status and implement run history.
  @override
  Future<void> run(DisplayVideo360Client client, Target target) async {
    final lineItemTarget = target as LineItemTarget;

    final status = 'ENTITY_STATUS_'
        '${proto.ChangeLineItemStatusParams_Status.valueOf(_statusValue).name}';

    await client.changeLineItemStatus(
        lineItemTarget.advertiserId, lineItemTarget.lineItemId, status);
  }
}

/// A class that represents changing the line item bidding strategy.
class ChangeLineItemBiddingStrategyAction implements Action {
  /// The integer value of the bidding strategy.
  int _biddingStrategy;

  /// The integer value of the performance goal.
  int _performanceGoal;

  /// The fixed bid amount.
  Int64 _bidAmount;

  /// The goal amount.
  Int64 _goalAmount;

  /// Creates a [ChangeLineItemBiddingStrategyAction] instance from a
  /// [proto.Action].
  ChangeLineItemBiddingStrategyAction(proto.Action action) {
    _biddingStrategy =
        action.changeLineItemBiddingStrategyParams.biddingStrategy.value;
    switch (action.changeLineItemBiddingStrategyParams.biddingStrategy) {
      case proto.ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED:
        _bidAmount = action.changeLineItemBiddingStrategyParams
            .fixedBidStrategyParams.bidAmountMicros;
        break;
      case proto
          .ChangeLineItemBiddingStrategyParams_BiddingStrategy.MAXIMIZE_SPEND:
        _performanceGoal = action.changeLineItemBiddingStrategyParams
            .maximizeSpendBidStrategyParams.type.value;
        break;
      case proto
          .ChangeLineItemBiddingStrategyParams_BiddingStrategy.PERFORMANCE_GOAL:
        _performanceGoal = action.changeLineItemBiddingStrategyParams
            .performanceGoalBidStrategyParams.type.value;
        _goalAmount = action.changeLineItemBiddingStrategyParams
            .performanceGoalBidStrategyParams.performanceGoalAmountMicros;
        break;
      default:
        throw UnsupportedError(
            '${action.changeLineItemBiddingStrategyParams.biddingStrategy} '
                'is not a supported stategy type.');
    }
  }

  /// Creates a [proto.Action].
  @override
  proto.Action toProto() {
    final action = proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_BIDDING_STRATEGY;

    switch (_biddingStrategy) {
      case 1:
        // Fixed bid strategy.
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED
              ..fixedBidStrategyParams = (proto.FixedBidStrategyParams()
                ..bidAmountMicros = _bidAmount);
        break;
      case 2:
        // Maximize spend bid strategy.
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy
                  .MAXIMIZE_SPEND
              ..maximizeSpendBidStrategyParams =
                  (proto.MaximizeSpendBidStrategyParams()
                    ..type = proto.BiddingStrategyPerformanceGoalType.valueOf(
                        _performanceGoal));
        break;
      case 3:
        // Performance goal bid strategy.
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy
                  .PERFORMANCE_GOAL
              ..performanceGoalBidStrategyParams =
                  (proto.PerformanceGoalBidStrategyParams()
                    ..type = proto.BiddingStrategyPerformanceGoalType.valueOf(
                        _performanceGoal)
                    ..performanceGoalAmountMicros = _goalAmount);
        break;
      default:
        throw UnsupportedError(
            '$_biddingStrategy is an invalid value for a bidding strategy.');
    }
    return action;
  }

  /// Changes the bidding strategy of the line item using the DV360 client.
  @override
  Future<void> run(DisplayVideo360Client client, Target target) async {
    final lineItemTarget = target as LineItemTarget;

    String goal;
    String strategy;
    switch (_biddingStrategy) {
      case 1:
        strategy = 'FIXED';
        break;
      case 2:
        strategy = 'MAXIMIZE_SPEND';
        break;
      case 3:
        strategy = 'PERFORMANCE_GOAL';
        break;
      default:
        throw UnsupportedError(
            '$_biddingStrategy is an invalid value for a bidding strategy.');
    }

    if (_biddingStrategy != 1) {
      // If the bidding strategy is maximize spend, performance goal, or
      // unspecified.
      switch (_performanceGoal) {
        case 1:
          // CPA goal.
          goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPA';
          break;
        case 2:
          // CPC goal.
          goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_CPC';
          break;
        case 3:
          // Viewable impressions goal.
          if (_biddingStrategy == 2) {
            // If maximize spend strategy:
            goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_AV_VIEWED';
          }
          if (_biddingStrategy == 3) {
            // If performance goal strategy
            goal = 'BIDDING_STRATEGY_PERFORMANCE_GOAL_TYPE_VIEWABLE_CPM';
          }
          break;
        default:
          throw UnsupportedError(
              '$_performanceGoal is an invalid value for a performance goal.');
      }
    }

    await client.changeLineItemBiddingStrategy(lineItemTarget.advertiserId,
        lineItemTarget.lineItemId, strategy,
        bidAmount: _bidAmount, goal: goal, goalAmount: _goalAmount);
  }
}
