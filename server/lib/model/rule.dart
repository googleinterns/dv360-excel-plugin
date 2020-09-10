import '../proto/rule.pb.dart' as proto;
import 'action.dart';
import 'condition.dart';
import 'scope.dart';

/// A class that represents a rule to manipulate DV360 entities.
class Rule {
  /// An [Action] instance that manipulates DV360 entities.
  final Action action;

  /// The [Scope] for the rule.
  final Scope scope;

  /// A bool that is true if the rule is scheduled to repeat, false otherwise.
  final bool isRepeating;

  /// A year to verify a one-time schedule. Null if [isRepeating] is true.
  int year;

  /// The [Condition] for the rule.
  final Condition condition;

  /// Creates a [Rule] from a [proto.Rule].
  Rule.fromProto(proto.Rule protoRule)
      : action = Action.getActionFromProto(protoRule.action),
        scope = Scope.getScopeFromProto(protoRule.scope),
        condition = Condition.getConditionFromProto(protoRule.condition),
        isRepeating = protoRule.schedule.type == proto.Schedule_Type.REPEATING {
    if (!isRepeating) {
      year = protoRule.schedule.oneTimeParams.year;
    }
  }
}
