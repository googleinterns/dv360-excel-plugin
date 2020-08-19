import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

import '../proto/create_user_request.pb.dart';
import '../service/firestore.dart';
import '../utils.dart';

/// A controller that handles operations on users.
class UserController extends ResourceController {
  /// The client used to interact with Firestore.
  final FirestoreClient _client;

  /// The AES key used to encrypt/decrypt the refresh token.
  final String _aesKey;

  /// Creates an instance of [UserController].
  UserController(this._client, this._aesKey);

  /// The accepted content types for this controller.
  @override
  List<ContentType> acceptedContentTypes = [
    ContentType('application', 'x-protobuf')
  ];

  /// Creates a user with a user ID and encrypted refresh token.
  ///
  /// Throws an [ArgumentError] if the request does not contain an Authorization
  /// header. Throws an [ApiRequestError] if the Firestore API returns an error.
  /// Returns a 200 OK [Response] upon success.
  @Operation.post()
  Future<Response> createUser(@Bind.body() List<int> body) async {
    final message = CreateUserRequest.fromBuffer(body);

    // The ID token is sent in the `Authorization` header of the request.
    final authorizationHeader = request.raw.headers.value('Authorization');
    if (authorizationHeader == null) {
      throw ArgumentError('Request does not contain an Authorization header');
    }
    final idToken = authorizationHeader.split(' ').last;

    // Gets the user's obfuscated Gaia ID and encrypt the refresh token.
    final userId = getUserId(idToken);
    final encryptedToken = encryptRefreshToken(message.refreshToken, _aesKey);

    await _client.createUser(userId, encryptedToken);

    return Response.ok({});
  }
}
