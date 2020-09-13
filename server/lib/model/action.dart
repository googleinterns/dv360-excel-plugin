import '../proto/rule.pb.dart' as proto;
import 'change_line_item_bidding_strategy_action.dart';
import 'change_line_item_status_action.dart';

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
