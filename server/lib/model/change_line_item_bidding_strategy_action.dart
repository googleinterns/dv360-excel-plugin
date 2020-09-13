import 'package:fixnum/fixnum.dart';

import '../proto/rule.pb.dart' as proto;
import 'action.dart';

enum BidStrategyType {
  unspecified,
  fixed,
  maximizeSpend,
  performanceGoal,
}

enum PerformanceGoalType {
  unspecified,
  cpa,
  cpc,
  viewableImpressions,
}

/// A class that represents changing the line item bidding strategy.
class ChangeLineItemBiddingStrategyAction implements Action {
  /// The bidding strategy.
  BidStrategyType biddingStrategy;

  /// The performance goal.
  PerformanceGoalType performanceGoal;

  /// The fixed bid amount.
  Int64 bidAmount;

  /// The goal amount.
  Int64 goalAmount;

  /// Creates a [ChangeLineItemBiddingStrategyAction] instance from a
  /// [proto.Action].
  ChangeLineItemBiddingStrategyAction(proto.Action action) {
    final parameters = action.changeLineItemBiddingStrategyParams;

    biddingStrategy = BidStrategyType.values[parameters.biddingStrategy.value];
    switch (biddingStrategy) {
      case BidStrategyType.fixed:
        break;
      case BidStrategyType.maximizeSpend:
        performanceGoal = PerformanceGoalType
            .values[parameters.maximizeSpendBidStrategyParams.type.value];
        break;
      case BidStrategyType.performanceGoal:
        performanceGoal = PerformanceGoalType
            .values[parameters.performanceGoalBidStrategyParams.type.value];
        goalAmount = parameters
            .performanceGoalBidStrategyParams.performanceGoalAmountMicros;
        break;
      default:
        throw UnsupportedError('${parameters.biddingStrategy} '
            'is not a supported stategy type.');
    }
  }

  /// Creates a [proto.Action].
  @override
  proto.Action toProto() {
    final action = proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_BIDDING_STRATEGY;

    switch (biddingStrategy) {
      case BidStrategyType.fixed:
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy.FIXED
              ..fixedBidStrategyParams =
                  (proto.FixedBidStrategyParams()..bidAmountMicros = bidAmount);
        break;
      case BidStrategyType.maximizeSpend:
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy
                  .MAXIMIZE_SPEND
              ..maximizeSpendBidStrategyParams =
                  (proto.MaximizeSpendBidStrategyParams()
                    ..type = proto.BiddingStrategyPerformanceGoalType.valueOf(
                        performanceGoal.index));
        break;
      case BidStrategyType.performanceGoal:
        action.changeLineItemBiddingStrategyParams =
            proto.ChangeLineItemBiddingStrategyParams()
              ..biddingStrategy = proto
                  .ChangeLineItemBiddingStrategyParams_BiddingStrategy
                  .PERFORMANCE_GOAL
              ..performanceGoalBidStrategyParams =
                  (proto.PerformanceGoalBidStrategyParams()
                    ..type = proto.BiddingStrategyPerformanceGoalType.valueOf(
                        performanceGoal.index)
                    ..performanceGoalAmountMicros = goalAmount);
        break;
      default:
        final biddingStrategyName =
            proto.ChangeLineItemBiddingStrategyParams_BiddingStrategy.valueOf(
                biddingStrategy.index);
        throw UnsupportedError(
            '$biddingStrategyName is an invalid bidding strategy.');
    }
    return action;
  }
}
