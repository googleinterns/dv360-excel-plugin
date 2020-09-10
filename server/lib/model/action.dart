import 'package:fixnum/fixnum.dart';

import '../proto/rule.pb.dart' as proto;

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
}

/// A class that represents changing the line item status.
///
/// The line item can be activated or paused.
class ChangeLineItemStatusAction implements Action {
  /// The integer value of the target line item status.
  int statusValue;

  /// Creates a [ChangeLineItemStatusAction] instance from a [proto.Action].
  ChangeLineItemStatusAction(proto.Action action) {
    statusValue = action.changeLineItemStatusParams.status.value;
  }

  /// Creates a [proto.Action] with Change line Item Status parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
        ..status =
            proto.ChangeLineItemStatusParams_Status.valueOf(statusValue));
  }
}

/// A class that represents changing the line item bidding strategy.
class ChangeLineItemBiddingStrategyAction implements Action {
  /// The integer value of the bidding strategy.
  int biddingStrategy;

  /// The integer value of the performance goal.
  int performanceGoal;

  /// The fixed bid amount.
  Int64 bidAmount;

  /// The goal amount.
  Int64 goalAmount;

  /// Creates a [ChangeLineItemBiddingStrategyAction] instance from a
  /// [proto.Action].
  ChangeLineItemBiddingStrategyAction(proto.Action action) {
    biddingStrategy =
        action.changeLineItemBiddingStrategyParams.biddingStrategy.value;
    switch (action.changeLineItemBiddingStrategyParams.biddingStrategy) {
      case proto.ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED:
        bidAmount = action.changeLineItemBiddingStrategyParams
            .fixedBidStrategyParams.bidAmountMicros;
        break;
      case proto
          .ChangeLineItemBiddingStrategyParams_BiddingStrategy.MAXIMIZE_SPEND:
        performanceGoal = action.changeLineItemBiddingStrategyParams
            .maximizeSpendBidStrategyParams.type.value;
        break;
      case proto
          .ChangeLineItemBiddingStrategyParams_BiddingStrategy.PERFORMANCE_GOAL:
        performanceGoal = action.changeLineItemBiddingStrategyParams
            .performanceGoalBidStrategyParams.type.value;
        goalAmount = action.changeLineItemBiddingStrategyParams
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

    switch (biddingStrategy) {
      case 1:
        // Fixed bid strategy.
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED
              ..fixedBidStrategyParams =
                  (proto.FixedBidStrategyParams()..bidAmountMicros = bidAmount);
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
                        performanceGoal));
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
                        performanceGoal)
                    ..performanceGoalAmountMicros = goalAmount);
        break;
      default:
        final biddingStrategyName =
            proto.ChangeLineItemBiddingStrategyParams_BiddingStrategy.valueOf(
                biddingStrategy);
        throw UnsupportedError(
            '$biddingStrategyName is an invalid value for a bidding strategy.');
    }
    return action;
  }
}
