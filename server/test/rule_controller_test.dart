import 'package:aqueduct/aqueduct.dart';
import 'package:fixnum/fixnum.dart';
import 'package:jose/jose.dart';
import 'package:mock_request/mock_request.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:server/controller/rule_controller.dart';
import 'package:server/proto/create_rule_request.pb.dart';
import 'package:server/proto/rule.pb.dart' as proto;
import 'package:server/service/firestore.dart';
import 'package:server/service/scheduler.dart';

class MockFirestoreClient extends Mock implements FirestoreClient {}

class MockSchedulerClient extends Mock implements SchedulerClient {}

Future<void> main() async {
  const userId = '123abc';
  const ruleId = 'abc123';
  Response response;
  proto.Rule ruleWithId;

  final rule = proto.Rule()
    ..name = 'My new rule'
    ..action = (proto.Action()
      ..type = proto.Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (proto.ChangeLineItemStatusParams()
        ..status = proto.ChangeLineItemStatusParams_Status.PAUSED))
    ..schedule = (proto.Schedule()
      ..type = proto.Schedule_Type.REPEATING
      ..timezone = 'America/Los_Angeles'
      ..repeatingParams =
      (proto.Schedule_RepeatingParams()..cronExpression = '* * * * *'))
    ..scope = (proto.Scope()
      ..type = proto.Scope_Type.LINE_ITEM_TYPE
      ..lineItemScopeParams = (proto.LineItemScopeParams()
        ..lineItemIds.add(Int64(12345))
        ..advertiserId = Int64(67890)));
  final createRuleRequest = CreateRuleRequest()..rule = rule;

  // Sets up the mock Firestore client, Scheduler client and rule controller.
  final mockFirestoreClient = MockFirestoreClient();
  when(mockFirestoreClient.createRule(any, any))
      .thenAnswer((_) async => ruleId);
  final mockSchedulerClient = MockSchedulerClient();
  final ruleController =
      RuleController(mockFirestoreClient, mockSchedulerClient);

  // Creates a random JWK to generate a valid ID token.
  final jsonWebKey = JsonWebKey.generate('RS256');
  final jwsBuilder = JsonWebSignatureBuilder();
  jwsBuilder.jsonContent =
      JsonWebTokenClaims.fromJson({'sub': userId}).toJson();
  jwsBuilder.addRecipient(jsonWebKey);
  final idToken = jwsBuilder.build().toCompactSerialization();

  group('Success case: createRule()', () {
    setUp(() async {
      ruleController.request = Request(
          MockHttpRequest('POST', Uri.parse('/rules'))
            ..headers.add('Content-Type', 'application/x-protobuf')
            ..headers.add('Authorization', 'Bearer $idToken'));
      response =
          await ruleController.createRule(createRuleRequest.writeToBuffer());
      ruleWithId = rule.clone()..id = ruleId;
    });

    test('calls FirestoreClient.createRule() with correct arguments', () async {
      verify(mockFirestoreClient.createRule(userId, ruleWithId));
    });

    test('calls schedulerClient.scheduleRule() with correct arguments', () async {
      verify(mockSchedulerClient.scheduleRule(userId, ruleWithId));
    });

    test('returns with an OK 200 upon success', () async {
      expect(response.statusCode, equals(200));
    });
  });

  group('Failure case: createRule()', () {
    setUp(() {
      ruleController.request = Request(
          MockHttpRequest('POST', Uri.parse('/rules'))
            ..headers.add('Content-Type', 'application/x-protobuf'));
    });

    test('throws an ArgumentError if Authorization header missing', () async {
      Future<void> actual() async {
        await ruleController.createRule(createRuleRequest.writeToBuffer());
      }

      expect(actual, throwsA(const TypeMatcher<ArgumentError>()));
    });
  });
}
