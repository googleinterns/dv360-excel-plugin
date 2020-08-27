import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:encrypt/encrypt.dart';
import 'package:fixnum/fixnum.dart';
import 'package:http/http.dart' as http;
import 'package:mock_request/mock_request.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:server/controller/run_rule_controller.dart';
import 'package:server/proto/scheduled_rule.pb.dart';
import 'package:server/proto/rule.pb.dart' as proto;
import 'package:server/service/firestore.dart';
import 'package:server/service/google_api.dart';
import 'package:server/utils.dart';

class MockGoogleApi extends Mock implements GoogleApi {}

class MockFirestoreClient extends Mock implements FirestoreClient {}

Future<void> main() async {
  const mockServerPort = 8005;
  final mockDisplayVideo360Server = MockHTTPServer(mockServerPort);
  const mockDv360Url = 'http://localhost:$mockServerPort/';

  const userId = '123abc';
  const ruleId = 'abc123';

  final rule = proto.Rule()
    ..name = 'test'
    ..id = ruleId
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

  final scheduledRule = ScheduledRule()
    ..ruleId = ruleId
    ..userId = userId;

  final refreshTokenKey = Key.fromSecureRandom(32).base64;
  const refreshToken = 'abc';
  final encryptedToken = encryptRefreshToken(refreshToken, refreshTokenKey);

  Response response;
  final mockGoogleApi = MockGoogleApi();
  final mockFirestoreClient = MockFirestoreClient();
  final runRuleController = RunRuleController(
      mockGoogleApi, mockFirestoreClient, refreshTokenKey, mockDv360Url);

  setUpAll(() async {
    await mockDisplayVideo360Server.open();
  });

  tearDownAll(() async {
    await mockDisplayVideo360Server.close();
  });

  tearDown(() async {
    mockDisplayVideo360Server.clear();
  });

  group('Success case: runRule()', () {
    setUp(() async {
      runRuleController.request = Request(
          MockHttpRequest('POST', Uri.parse('/run_rule'))
            ..headers.add('Content-Type', 'application/x-protobuf'));
      when(mockGoogleApi.getUserAccountClient(refreshToken))
          .thenAnswer((_) async => http.Client());
      when(mockFirestoreClient.getEncryptedUserRefreshToken(userId))
          .thenAnswer((_) async => encryptedToken);
      when(mockFirestoreClient.getRule(userId, ruleId))
          .thenAnswer((_) async => rule);
      mockDisplayVideo360Server.queueResponse(Response.ok({}));

      response = await runRuleController.runRule(scheduledRule.writeToBuffer());
    });

    test('calls FirestoreClient.getRule() with correct arguments', () async {
      verify(mockFirestoreClient.getRule(userId, ruleId));
    });

    test('calls FirestoreClient.getEncryptedUserRefreshToken() with user ID',
        () async {
      verify(mockFirestoreClient.getEncryptedUserRefreshToken(userId));
    });

    test('calls GoogleApi.getUserAccountClient() with decrypted token',
        () async {
      verify(mockGoogleApi.getUserAccountClient(refreshToken));
    });

    test('returns with an OK 200 upon success', () async {
      expect(response.statusCode, 200);
    });
  });
}
