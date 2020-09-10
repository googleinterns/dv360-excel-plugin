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
      case proto.Action_Type.DUPLICATE_LINE_ITEM:
        return DuplicateLineItemAction(action);
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

/// A class that represents duplicating line items.
class DuplicateLineItemAction implements Action {
  /// The destination advertiser ID.
  final Int64 _advertiserId;

  /// The destination insertion order ID.
  final Int64 _insertionOrderId;

  /// Creates a [DuplicateLineItemAction] instance from a [proto.Action].
  DuplicateLineItemAction(proto.Action action)
      : _advertiserId = action.duplicateLineItemParams.advertiserId,
        _insertionOrderId = action.duplicateLineItemParams.insertionOrderId;

  /// Creates a [proto.Action] with Duplicate Line Item parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.DUPLICATE_LINE_ITEM
      ..duplicateLineItemParams = (proto.DuplicateLineItemParams()
        ..advertiserId = _advertiserId
        ..insertionOrderId = _insertionOrderId);
  }

  /// Duplicates the line items using the DV360 client.
  @override
  Future<void> run(DisplayVideo360Client client, Target target) async {
    final lineItemTarget = target as LineItemTarget;

    await client.duplicateLineItem(lineItemTarget.advertiserId,
        lineItemTarget.lineItemId, _advertiserId, _insertionOrderId);
  }
}
