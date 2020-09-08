import 'package:fixnum/fixnum.dart';

import '../proto/rule.pb.dart' as proto;

/// A class that represents the target entities for the rule.
class Scope {
  /// A list of target DV360 entities.
  List<Target> targets = [];

  /// Creates an instance of a class that implements [Scope] from a proto.
  ///
  /// Throws an [UnsupportedError] if the proto's scope type is unspecified.
  static Scope getScopeFromProto(proto.Scope scope) {
    switch (scope.type) {
      case proto.Scope_Type.LINE_ITEM_TYPE:
        final scopeModel = Scope();
        final advertiserId = scope.lineItemScopeParams.advertiserId;
        for (final lineItemId in scope.lineItemScopeParams.lineItemIds) {
          scopeModel.targets.add(LineItemTarget(lineItemId, advertiserId));
        }
        return scopeModel;
      default:
        throw UnsupportedError('${scope.type} is not a supported scope type.');
    }
  }
}

/// An interface to represent a target DV360 entity.
abstract class Target {}

/// A class to represent a DV360 line item target.
class LineItemTarget implements Target {
  /// The line item ID.
  Int64 lineItemId;

  /// The advertiser ID of the line item.
  Int64 advertiserId;

  /// Creates an instance of [LineItemTarget].
  LineItemTarget(this.lineItemId, this.advertiserId);
}
