import '../proto/rule.pb.dart' as proto;
import 'action.dart';
import 'scope.dart';

/// A class that represents a rule to manipulate DV360 entities.
class Rule {
  /// An [Action] instance that manipulates DV360 entities.
  final Action action;

  /// The [Scope] for the rule.
  final Scope scope;

  /// Creates a [Rule] from a [proto.Rule].
  Rule.fromProto(proto.Rule protoRule)
      : action = Action.getActionFromProto(protoRule.action),
        scope = Scope.getScopeFromProto(protoRule.scope);
}
