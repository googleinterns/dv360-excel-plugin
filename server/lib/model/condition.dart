import 'dart:async';

import 'package:meta/meta.dart';
import 'package:http/http.dart';

import '../proto/rule.pb.dart' as proto;
import '../service/reporting.dart';
import 'scope.dart';

/// An interface that represents a condition for a rule.
abstract class Condition {
  /// Creates an instance of a class that implements [Condition], from a proto.
  ///
  /// Throws an [UnsupportedError] if the proto's condition type is unspecified.
  static Condition getConditionFromProto(proto.Condition condition) {
    switch (condition.type) {
      case proto.Condition_Type.CPM:
        return LineItemCpmCondition(condition);
      default:
        throw UnsupportedError(
            '${condition.type} is not a supported condition type.');
    }
  }

  /// Checks if the condition is true for the [target].
  Future<bool> isTrue(Target target, {ReportingClient client});
}

class LineItemCpmCondition implements Condition {
  final ReportingClient _reportingClient;
  final String _relation;
  final double _value;

  /// Creates a [LineItemCpmCondition] instance from a [proto.Condition].
  LineItemCpmCondition(proto.Condition condition)
      : _reportingClient = ReportingClient(Client()),
        _relation = condition.relation.name,
        _value = condition.value;

  @override

  /// Checks the condition using the [ReportingClient].
  Future<bool> isTrue(Target target, {@required ReportingClient client}) async {
    final lineItemTarget = target as LineItemTarget;

    final cpm = await _reportingClient.getLineItemCpm(
        lineItemTarget.advertiserId, lineItemTarget.lineItemId);

    switch (_relation) {
      case 'LESSER_EQUAL':
        return cpm <= _value;
      case 'GREATER':
        return cpm > _value;
      default:
        throw UnsupportedError('$_relation is not a supported relation type.');
    }
  }
}
