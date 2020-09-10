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
      case proto.Action_Type.DUPLICATE_LINE_ITEM:
        return DuplicateLineItemAction(action);
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

/// A class that represents duplicating line items.
class DuplicateLineItemAction implements Action {
  /// The destination advertiser ID.
  final Int64 advertiserId;

  /// The destination insertion order ID.
  final Int64 insertionOrderId;

  /// Creates a [DuplicateLineItemAction] instance from a [proto.Action].
  DuplicateLineItemAction(proto.Action action)
      : advertiserId = action.duplicateLineItemParams.advertiserId,
        insertionOrderId = action.duplicateLineItemParams.insertionOrderId;

  /// Creates a [proto.Action] with Duplicate Line Item parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.DUPLICATE_LINE_ITEM
      ..duplicateLineItemParams = (proto.DuplicateLineItemParams()
        ..advertiserId = advertiserId
        ..insertionOrderId = insertionOrderId);
  }
}
