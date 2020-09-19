import 'package:aqueduct/aqueduct.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:jose/jose.dart';
import 'package:mock_request/mock_request.dart';
import 'package:test/test.dart';

import 'package:server/controller/id_token_validator.dart';

void main() {
  // The claims to be used in the ID token.
  final idTokenClaims = JsonWebTokenClaims.fromJson({
    'sub': '123',
  });

  // Creates a random JWK to generate a valid ID token.
  final jsonWebKey = JsonWebKey.generate('RS256');
  final jwsBuilder = JsonWebSignatureBuilder();
  jwsBuilder.jsonContent = idTokenClaims.toJson();
  jwsBuilder.addRecipient(jsonWebKey);
  final validIdToken = jwsBuilder.build().toCompactSerialization();

  // Creates a random JWK to generate an invalid ID token.
  final invalidJsonWebKey = JsonWebKey.generate('RS256');
  final invalidJwsBuilder = JsonWebSignatureBuilder();
  invalidJwsBuilder.jsonContent = idTokenClaims.toJson();
  invalidJwsBuilder.addRecipient(invalidJsonWebKey);
  final invalidIdToken = invalidJwsBuilder.build().toCompactSerialization();

  // Sets up the mock key server.
  final jsonWebKeySet = JsonWebKeySet.fromKeys([jsonWebKey]);
  const mockServerPort = 8004;
  final mockKeyServer = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort';

  // Sets up validator controller.
  final validator = IdTokenValidator(keysUrl: url);

  // Sets up requests used in testing.
  final invalidHeadersReq = Request(MockHttpRequest('GET', Uri.parse('/test')));
  final validReq = Request(MockHttpRequest('GET', Uri.parse('/test'))
    ..headers.add('Authorization', 'Bearer $validIdToken'));
  final invalidReq = Request(MockHttpRequest('GET', Uri.parse('/test'))
    ..headers.add('Authorization', 'Bearer $invalidIdToken'));

  setUpAll(() async {
    await mockKeyServer.open();
  });

  tearDownAll(() async {
    await mockKeyServer.close();
  });

  tearDown(() async {
    mockKeyServer.clear();
  });

  group('handle()', () {
    setUp(() async {
      mockKeyServer.queueResponse(Response.ok(jsonWebKeySet.toJson()));
    });

    test('throws an ArgumentError when headers are invalid', () async {
      Future<void> actual() async => await validator.handle(invalidHeadersReq);

      expect(actual, throwsA(const TypeMatcher<ArgumentError>()));
    });

    test('returns the request for a valid ID token', () async {
      final request = await validator.handle(validReq);

      expect(request, equals(validReq));
    });

    test('returns 401 Unauthorized response for an invalid ID token', () async {
      final response = await validator.handle(invalidReq);

      expect((response as Response).statusCode, equals(401));
    });
  });
}
