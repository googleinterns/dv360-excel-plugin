import 'package:proto/rule.pb.dart' as proto;

import 'action.dart';

enum StatusType {
  unspecified,
  active,
  paused,
}

/// A class that represents changing the line item status.
///
/// The line item can be activated or paused.
class ChangeLineItemStatusAction implements Action {
  /// The target line item status.
  StatusType statusValue;

  /// Creates a [ChangeLineItemStatusAction] instance from a [proto.Action].
  ChangeLineItemStatusAction(proto.Action action) {
    statusValue =
        StatusType.values[action.changeLineItemStatusParams.status.value];
  }

  /// Creates a [proto.Action] with Change line Item Status parameters.
  @override
  proto.Action toProto() {
    return proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
        ..status =
            proto.ChangeLineItemStatusParams_Status.valueOf(statusValue.index));
  }
}
