import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart' as firestore;
import 'package:googleapis/discovery/v1.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:server/proto/rule.pb.dart';
import 'package:server/service/firestore.dart';
import 'package:server/utils.dart';

void main() {
  const mockServerPort = 8002;
  final mockFirestoreServer = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort/';

  const projectId = 'spreadsheet-dv360-plugin';
  const databaseId = '(default)';
  const ruleName = 'testRule';
  const documentName = 'testDocument';
  const userId = '1234567890';
  const parent = 'projects/$projectId/databases/$databaseId/documents';
  const ruleResourceName =
      '$parent/${FirestoreClient.usersName}/$userId/'
      '${FirestoreClient.rulesName}';
  const userCollectionResourceName =
      '$parent/${FirestoreClient.usersName}';
  const encryptedRefreshToken = 'abc123';

  final rule = Rule()
    ..name = ruleName
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

  final client = http.Client();
  final firestoreClient = FirestoreClient(client, projectId, databaseId, url);

  Request request;
  String returnedString;
  firestore.Document userDocument;

  setUpAll(() async {
    await mockFirestoreServer.open();
  });

  tearDownAll(() async {
    await mockFirestoreServer.close();
  });

  tearDown(() async {
    mockFirestoreServer.clear();
  });

  group('Success case: createRule()', () {
    setUp(() async {
      final ruleAsDocument = rule.toDocument();
      ruleAsDocument.name = documentName;

      mockFirestoreServer.queueResponse(Response.ok(ruleAsDocument.toJson()));

      returnedString = await firestoreClient.createRule(userId, rule);
      request = await mockFirestoreServer.next();
    });

    test('makes a POST request', () async {
      expect(request.method, equals('POST'));
    });

    test('makes a request that goes to the correct path', () async {
      expect(request.path.string, '/v1/$ruleResourceName');
    });

    test(
        'makes a request with a body that contains a Document equivalent '
        'to the rule', () async {
      final document = firestore.Document.fromJson(await request.body.decode());

      expect(document.toJson(), equals(rule.toDocument().toJson()));
    });

    test('returns the correct document name', () async {
      expect(returnedString, equals(documentName));
    });
  });

  group('Failure case: createRule()', () {
    test('throws an ApiRequestError when there is an API error', () async {
      mockFirestoreServer.queueResponse(Response.notFound());

      Future<void> actual() async =>
          await firestoreClient.createRule(userId, rule);

      expect(actual, throwsA(const TypeMatcher<ApiRequestError>()));
    });
  });

  group('Success case: createUser()', () {
    setUp(() async {
      userDocument = firestore.Document()
        ..name = userId
        ..fields = {
          FirestoreClient.encryptedRefreshTokenFieldName: firestore.Value()
            ..stringValue = encryptedRefreshToken
        };

      mockFirestoreServer.queueResponse(Response.ok(userDocument.toJson()));

      await firestoreClient.createUser(userId, encryptedRefreshToken);
      request = await mockFirestoreServer.next();
    });

    test('makes a POST request', () async {
      expect(request.method, equals('POST'));
    });

    test('makes a request that goes to the correct path', () async {
      expect(request.path.string, '/v1/$userCollectionResourceName');
    });

    test(
        'makes a request with a body that contains a Document equivalent '
        'to the newly created user', () async {
      final document = firestore.Document.fromJson(await request.body.decode())
        ..name = userId;

      expect(document.toJson(), equals(userDocument.toJson()));
    });
  });

  group('Failure case: createUser()', () {
    test('throws an ApiRequestError when there is an API error', () async {
      mockFirestoreServer.queueResponse(Response.notFound());

      Future<void> actual() async =>
          await firestoreClient.createUser(userId, encryptedRefreshToken);

      expect(actual, throwsA(const TypeMatcher<ApiRequestError>()));
    });
  });

  group('Success case: getEncryptedUserRefreshToken()', () {
    setUp(() async {
      userDocument = firestore.Document()
        ..name = userId
        ..fields = {
          FirestoreClient.encryptedRefreshTokenFieldName: firestore.Value()
            ..stringValue = encryptedRefreshToken
        };
      mockFirestoreServer.queueResponse(Response.ok(userDocument.toJson()));

      await firestoreClient.getEncryptedUserRefreshToken(userId);
      request = await mockFirestoreServer.next();
    });

    test('makes a GET request', () async {
      expect(request.method, equals('GET'));
    });

    test('makes a request that goes to the correct path', () async {
      expect(request.path.string, '/v1/$userCollectionResourceName/$userId');
    });

    test('Request body is empty', () async {
      expect(request.body, isEmpty);
    });
  });

  group('Failure case: getEncryptedUserRefreshToken()', () {
    test('throws an ApiRequestError when there is an API error', () async {
      mockFirestoreServer.queueResponse(Response.notFound());

      Future<void> actual() async =>
          await firestoreClient.getEncryptedUserRefreshToken(userId);

      expect(actual, throwsA(const TypeMatcher<ApiRequestError>()));
    });
  });
}
