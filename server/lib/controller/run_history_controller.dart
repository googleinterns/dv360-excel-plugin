import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';

import '../service/firestore.dart';
import '../utils.dart';

/// A controller that handles requests for run history.
class RunHistoryController extends ResourceController {
  /// The client to interact with Firestore.
  final FirestoreClient _firestoreClient;

  /// Creates an instance of [RunHistoryController].
  RunHistoryController(this._firestoreClient);

  /// The accepted content types for this controller.
  @override
  List<ContentType> acceptedContentTypes = [
    ContentType('application', 'x-protobuf')
  ];

  /// Gets the run history for the rule with [ruleId].
  ///
  /// Throws an [ApiRequestError] if there is an error with the Firestore API.
  /// Returns a 200 OK response upon success.
  @Operation.get()
  Future<Response> getRunHistory(@Bind.query('ruleId') String ruleId) async {
    // The ID token is sent in the `Authorization` header of the request.
    final authorizationHeader = request.raw.headers.value('Authorization');
    if (authorizationHeader == null) {
      throw ArgumentError('Request does not contain an Authorization header');
    }
    final idToken = authorizationHeader.split(' ').last;
    final userId = getUserId(idToken);

    final response = await _firestoreClient.getRunHistory(userId, ruleId);

    return Response.ok(response.writeToBuffer())..encodeBody = false;
  }
}
