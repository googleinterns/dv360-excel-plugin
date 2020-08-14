import 'dart:async';

import '../proto/rule.pb.dart' as proto;
import '../service/dv360.dart';
import 'action.dart';

/// A class that represents a rule to manipulate DV360 entities.
class Rule {
  /// An [Action] instance that manipulates DV360 entities.
  final Action _action;

  /// Creates a [Rule] from a [proto.Rule].
  Rule.fromProto(proto.Rule protoRule)
      : _action = getActionFromProto(protoRule.action);

  /// Runs the rule using the [DisplayVideo360Client] client.
  Future<void> run(DisplayVideo360Client client) async {
    await _action.run(client);
  }
}
