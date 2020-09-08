import 'dart:async';

import 'package:jose/jose.dart';
import 'package:aqueduct/aqueduct.dart';

/// A middleware controller to validate the user's ID token.
///
/// Any request should first be handled by [IdTokenValidator].
class IdTokenValidator extends Controller {
  /// The url to Google's public keys in JWK format.
  final String _keysUrl;

  /// Creates an instance of [IdTokenValidator].
  IdTokenValidator(
      {String keysUrl = 'https://www.googleapis.com/oauth2/v3/certs'})
      : _keysUrl = keysUrl;

  /// Verifies the ID token is valid.
  ///
  /// Returns the [request] to the next linked controller upon success. Else,
  /// returns a 401 Unauthorized response to the user. Throws an [ArgumentError]
  /// when the Authorization header is missing.
  @override
  Future<RequestOrResponse> handle(Request request) async {
    // The ID token is sent in the `Authorization` header of the request.
    final authorizationHeader = request.raw.headers.value('Authorization');
    if (authorizationHeader == null) {
      throw ArgumentError('Request does not contain an Authorization header');
    }
    final encodedIdToken = authorizationHeader.split(' ').last;

    // Decodes the ID token.
    final jwt = JsonWebToken.unverified(encodedIdToken);

    // Creates a key store and adds Google's public keys.
    final keyStore = JsonWebKeyStore();
    keyStore.addKeySetUrl(Uri.parse(_keysUrl));

    // Verifies the ID token.
    final isVerified = await jwt.verify(keyStore);

    return isVerified ? request : Response.unauthorized();
  }
}
