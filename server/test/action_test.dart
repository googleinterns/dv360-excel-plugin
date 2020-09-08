import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:server/model/action.dart';
import 'package:server/model/scope.dart';
import 'package:server/proto/rule.pb.dart' as proto;
import 'package:server/service/dv360.dart';

class MockDisplayVideo360Client extends Mock implements DisplayVideo360Client {}

void main() {
  final lineItemId = Int64(12345);
  final advertiserId = Int64(67890);
  final target = LineItemTarget(lineItemId, advertiserId);

  final validActionProto = proto.Action()
    ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
    ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
      ..status = proto.ChangeLineItemStatusParams_Status.PAUSED);

  final unspecifiedActionProto = proto.Action()
    ..type = proto.Action_Type.UNSPECIFIED_TYPE;

  final mockClient = MockDisplayVideo360Client();

  group('Action\'s factory constructor', () {
    test('correctly creates a ChangeLineItemStatusAction instance', () {
      final actionModel = Action.getActionFromProto(validActionProto);

      expect(actionModel.runtimeType, equals(ChangeLineItemStatusAction));
    });

    test('throws an error if the action is unspecified', () {
      void actual() => Action.getActionFromProto(unspecifiedActionProto);

      expect(actual, throwsA(const TypeMatcher<UnsupportedError>()));
    });
  });

  group('ChangeLineItemStatusAction\'s method', () {
    test('toProto() produces an equivalent action proto', () async {
      final actionProto = Action.getActionFromProto(validActionProto).toProto();

      expect(actionProto, equals(validActionProto));
    });

    test('run() changes the line item status using the client', () async {
      final status = 'ENTITY_STATUS_'
          '${validActionProto.changeLineItemStatusParams.status.name}';
      final action = Action.getActionFromProto(validActionProto);

      await action.run(mockClient, target);

      verify(mockClient.changeLineItemStatus(advertiserId, lineItemId, status));
    });
  });
}
