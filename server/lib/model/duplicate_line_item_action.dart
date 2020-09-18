import 'package:fixnum/fixnum.dart';

import 'package:proto/rule.pb.dart' as proto;
import 'action.dart';

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
