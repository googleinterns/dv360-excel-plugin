import 'package:aqueduct/aqueduct.dart';
import 'package:encrypt/encrypt.dart';
import 'package:mock_request/mock_request.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:server/controller/run_rule_controller.dart';
import 'package:server/proto/scheduled_rule.pb.dart';
import 'package:server/proto/rule.pb.dart' as proto;
import 'package:server/model/rule.dart';
import 'package:server/service/dv360.dart';
import 'package:server/service/firestore.dart';
import 'package:server/service/google_api.dart';
import 'package:server/utils.dart';

class MockGoogleApi extends Mock implements GoogleApi {}

class MockFirestoreClient extends Mock implements FirestoreClient {}

class MockRule extends Mock implements Rule {}

class TestRunRuleController extends RunRuleController {
  TestRunRuleController(GoogleApi googleApi, FirestoreClient firestoreClient,
      String aesKey, String baseUrl)
      : super(googleApi, firestoreClient, aesKey, baseUrl);

  @override
  Rule getRule(proto.Rule ruleProto) {
    return mockRule = MockRule();
  }
}

MockRule mockRule;
Response response;

Future<void> main() async {
  const baseUrl = 'http://localhost:8005/';
  const userId = '123abc';
  const ruleId = 'abc123';

  final scheduledRule = ScheduledRule()
    ..ruleId = ruleId
    ..userId = userId;

  final refreshTokenKey = Key.fromSecureRandom(32).base64;
  const refreshToken = 'abc';
  final encryptedToken = encryptRefreshToken(refreshToken, refreshTokenKey);

  final mockGoogleApi = MockGoogleApi();
  final mockFirestoreClient = MockFirestoreClient();
  final runRuleController = TestRunRuleController(
      mockGoogleApi, mockFirestoreClient, refreshTokenKey, baseUrl);

  group('Success case: runRule()', () {
    setUp(() async {
      runRuleController.request = Request(
          MockHttpRequest('POST', Uri.parse('/run_rule'))
            ..headers.add('Content-Type', 'application/x-protobuf'));
      when(mockFirestoreClient.getEncryptedUserRefreshToken(userId))
          .thenAnswer((_) async => encryptedToken);

      response = await runRuleController.runRule(scheduledRule.writeToBuffer());
    });

    test('calls FirestoreClient.getRule() with user ID', () async {
      verify(mockFirestoreClient.getRule(userId, any));
    });

    test('calls FirestoreClient.getRule() with rule ID', () async {
      verify(mockFirestoreClient.getRule(any, ruleId));
    });

    test('calls FirestoreClient.getEncryptedUserRefreshToken() with user ID',
        () async {
      verify(mockFirestoreClient.getEncryptedUserRefreshToken(userId));
    });

    test('calls GoogleApi.getUserAccountClient() with decrypted token',
        () async {
      verify(mockGoogleApi.getUserAccountClient(refreshToken));
    });

    test('calls Rule.run() with DV360 client', () async {
      verify(mockRule.run(argThat(const TypeMatcher<DisplayVideo360Client>())));
    });

    test('returns with an OK 200 upon success', () async {
      expect(response.statusCode, 200);
    });
  });
}
