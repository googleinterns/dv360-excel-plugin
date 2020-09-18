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
    final encodedIdToken = getEncodedIdToken(request);
    final userId = getUserId(encodedIdToken);

    final response = await _firestoreClient.getRunHistory(userId, ruleId);

    return Response.ok(response.writeToBuffer())..encodeBody = false;
  }
}
