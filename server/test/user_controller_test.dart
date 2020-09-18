import 'package:encrypt/encrypt.dart';
import 'package:jose/jose.dart';
import 'package:mock_request/mock_request.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:proto/create_user_request.pb.dart';
import 'package:server/controller/user_controller.dart';
import 'package:server/service/firestore.dart';
import 'package:server/utils.dart';
import 'package:server/server.dart';

class MockFirestoreClient extends Mock implements FirestoreClient {}

Future<void> main() async {
  const userId = '123abc';
  const refreshToken = '12345test';
  final refreshTokenKey = Key.fromSecureRandom(32).base64;

  // Sets up the mock Firestore client and user controller.
  final mockFirestoreClient = MockFirestoreClient();
  final userController = UserController(mockFirestoreClient, refreshTokenKey);

  // Creates a random JWK to generate a valid ID token.
  final jsonWebKey = JsonWebKey.generate('RS256');
  final jwsBuilder = JsonWebSignatureBuilder();
  jwsBuilder.jsonContent =
      JsonWebTokenClaims.fromJson({'sub': userId}).toJson();
  jwsBuilder.addRecipient(jsonWebKey);
  final idToken = jwsBuilder.build().toCompactSerialization();

  final createUserRequest = CreateUserRequest()..refreshToken = refreshToken;
  Response response;

  group('Success case: createUser()', () {
    setUp(() async {
      userController.request = Request(
          MockHttpRequest('POST', Uri.parse('/users'))
            ..headers.add('Content-Type', 'application/x-protobuf')
            ..headers.add('Authorization', 'Bearer $idToken'));

      response =
          await userController.createUser(createUserRequest.writeToBuffer());
    });

    test('calls FirestoreClient.createUser() with user ID', () async {
      verify(mockFirestoreClient.createUser(userId, any));
    });

    test('calls FirestoreClient.createUser() with encrypted token', () async {
      final encryptedToken = encryptRefreshToken(refreshToken, refreshTokenKey);

      verify(mockFirestoreClient.createUser(any, encryptedToken));
    });

    test('returns with an OK 200 upon success', () async {
      expect(response.statusCode, equals(200));
    });
  });

  group('Failure case: createUser()', () {
    setUp(() {
      userController.request = Request(
          MockHttpRequest('POST', Uri.parse('/users'))
            ..headers.add('Content-Type', 'application/x-protobuf'));
    });

    test('throws an ArgumentError if Authorization header missing', () async {
      Future<void> actual() async {
        await userController.createUser(createUserRequest.writeToBuffer());
      }

      expect(actual, throwsA(const TypeMatcher<ArgumentError>()));
    });
  });
}
