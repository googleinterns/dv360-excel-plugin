import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:server/proto/rule.pb.dart';
import 'package:server/utils.dart';
import 'package:test/test.dart';

void main() {
  final rule = Rule()
    ..name = "My new rule"
    ..action = (Action()
      ..type = Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (ChangeLineItemStatusParams()
        ..lineItemIds.add(Int64(12345))
        ..advertiserId = Int64(67890)
        ..status = ChangeLineItemStatusParams_Status.PAUSED))
    ..schedule = (Schedule()
      ..type = Schedule_Type.REPEATING
      ..timezone = 'America/Los_Angeles'
      ..repeatingParams =
          (Schedule_RepeatingParams()..cronExpression = '* * * * *'));

  final document = Document()
    ..fields = {
      'name': (Value()..stringValue = 'My new rule'),
      'action': (Value()
        ..mapValue = (MapValue()
          ..fields = {
            'type': (Value()..stringValue = 'CHANGE_LINE_ITEM_STATUS'),
            'changeLineItemStatusParams': (Value()
              ..mapValue = (MapValue()
                ..fields = {
                  'lineItemIds': (Value()
                    ..arrayValue = (ArrayValue()
                      ..values = [Value()..stringValue = '12345'])),
                  'advertiserId': (Value()..stringValue = '67890'),
                  'status': (Value()..stringValue = 'PAUSED'),
                }))
          })),
      'schedule': (Value()
        ..mapValue = (MapValue()
          ..fields = {
            'type': (Value()..stringValue = 'REPEATING'),
            'timezone': (Value()..stringValue = 'America/Los_Angeles'),
            'repeatingParams': (Value()
              ..mapValue = (MapValue()
                ..fields = {
                  'cronExpression': Value()..stringValue = '* * * * *',
                }))
          }))
    };

  group('Rule-Document Conversion:', () {
    test('toDocument() converts a Rule to an equivalent Document', () async {
      final ruleAsDocument = rule.toDocument();

      // I haven't overridden [Document.equals()] yet, so currently just
      // comparing JSONs
      expect(ruleAsDocument.toJson(), equals(document.toJson()));
    });

    test('toProto() converts a Document to an equivalent Rule', () async {
      final documentAsRule = document.toProto();

      expect(documentAsRule, equals(rule));
    });
  });
}
