import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:server/model/action.dart';
import 'package:server/proto/rule.pb.dart' as proto;
import 'package:server/service/dv360.dart';

class MockDisplayVideo360Client extends Mock implements DisplayVideo360Client {}

void main() {
  final validActionProto = proto.Action()
    ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
    ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
      ..lineItemIds.add(Int64(34787229))
      ..advertiserId = Int64(3849739)
      ..status = proto.ChangeLineItemStatusParams_Status.PAUSED);

  final unspecifiedActionProto = proto.Action()
    ..type = proto.Action_Type.UNSPECIFIED_TYPE;

  final mockClient = MockDisplayVideo360Client();

  group('Action\'s factory constructor', () {
    test('correctly creates a ChangeLineItemStatusAction instance', () {
      final actionModel = Action.fromProto(validActionProto);

      expect(actionModel.runtimeType, equals(ChangeLineItemStatusAction));
    });

    test('throws an error if the action is unspecified', () {
      void actual() => Action.fromProto(unspecifiedActionProto);

      expect(actual, throwsA(const TypeMatcher<UnsupportedError>()));
    });
  });

  group('ChangeLineItemStatusAction\'s method', () {
    test('toProto() produces an equivalent action proto', () async {
      final actionProto = Action.fromProto(validActionProto).toProto();

      expect(actionProto, equals(validActionProto));
    });

    test('run() changes the line item status using the client', () async {
      final advertiserId =
          validActionProto.changeLineItemStatusParams.advertiserId;
      final lineItemId =
          validActionProto.changeLineItemStatusParams.lineItemIds[0];
      final status = 'ENTITY_STATUS_'
          '${validActionProto.changeLineItemStatusParams.status.name}';
      final action = Action.fromProto(validActionProto);

      await action.run(mockClient);

      verify(mockClient.changeLineItemStatus(advertiserId, lineItemId, status));
    });
  });
}
