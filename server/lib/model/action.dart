import 'dart:async';

import 'package:fixnum/fixnum.dart';

import '../proto/rule.pb.dart' as proto;
import '../service/dv360.dart';

/// An interface that represents an action to manipulate DV360 entities.
abstract class Action {
  /// Creates an instance of a class that implements [Action], from a proto.
  ///
  /// Throws an [UnsupportedError] if the proto's action type is unspecified.
  factory Action.fromProto(proto.Action action) {
    switch (action.type) {
      case proto.Action_Type.CHANGE_LINE_ITEM_STATUS:
        return ChangeLineItemStatusAction.fromProto(action);
      default:
        throw UnsupportedError(
            '${action.type} is not a supported action type.');
    }
  }

  /// Creates a proto that represents the [Action].
  proto.Action toProto();

  /// Executes the action using the [DisplayVideo360Client].
  Future<void> run(DisplayVideo360Client client);
}

/// A class that represents changing the line item status.
///
/// The line item(s) can be activated or paused.
class ChangeLineItemStatusAction implements Action {
  /// A list of target line item IDs for this action.
  List<Int64> lineItemIds = [];

  /// The advertiser ID for which the line items belong to.
  Int64 advertiserId;

  /// The integer value of the target line item status.
  int statusValue;

  /// Creates a [ChangeLineItemStatusAction] instance from a [proto.Action].
  ChangeLineItemStatusAction.fromProto(proto.Action action) {
    lineItemIds.addAll(action.changeLineItemStatusParams.lineItemIds);
    advertiserId = action.changeLineItemStatusParams.advertiserId;
    statusValue = action.changeLineItemStatusParams.status.value;
  }

  /// Creates a [proto.Action] with Change line Item Status parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
        ..lineItemIds.addAll(lineItemIds)
        ..advertiserId = advertiserId
        ..status =
            proto.ChangeLineItemStatusParams_Status.valueOf(statusValue));
  }

  /// Changes the status of the line item(s) using the DV360 client.
  @override
  Future<void> run(DisplayVideo360Client client) async {
    final status = 'ENTITY_STATUS_'
        '${proto.ChangeLineItemStatusParams_Status.valueOf(statusValue).name}';

    for (var lineItemId in lineItemIds) {
      await client.changeLineItemStatus(advertiserId, lineItemId, status);
    }
  }
}
