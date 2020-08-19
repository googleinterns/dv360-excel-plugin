import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:meta/meta.dart';

import '../model/rule.dart';
import '../proto/rule.pb.dart' as proto;
import '../proto/scheduled_rule.pb.dart';
import '../service/dv360.dart';
import '../service/firestore.dart';
import '../service/google_api.dart';
import '../utils.dart';

/// A controller that handles running rules.
class RunRuleController extends ResourceController {
  /// This provides authenticated clients to interact with Google APIs.
  final GoogleApi _googleApi;

  /// The client to interact with Firestore.
  final FirestoreClient _firestoreClient;

  /// The base URL of DV360.
  final String _dv360BaseUrl;

  /// The AES key to encrypt/decrypt refresh tokens.
  final String _aesKey;

  /// Creates an instance of [RunRuleController].
  RunRuleController(
      this._googleApi, this._firestoreClient, this._aesKey, this._dv360BaseUrl);

  /// The accepted content types for this controller.
  @override
  List<ContentType> acceptedContentTypes = [
    ContentType('application', 'x-protobuf')
  ];

  /// Runs the rule given by the [ScheduledRule] serialized in the request body.
  ///
  /// Throws an [ApiRequestError] if there is an error with the Firestore API
  /// or Display & Video 360 API. Returns a 200 OK response upon success.
  @Operation.post()
  Future<Response> runRule(@Bind.body() List<int> body) async {
    final scheduledRule = ScheduledRule.fromBuffer(body);
    final ruleId = scheduledRule.ruleId;
    final userId = scheduledRule.userId;

    // Looks up the rule in Firestore using (userId, ruleId) and creates model.
    final ruleProto = await _firestoreClient.getRule(userId, ruleId);
    final rule = getRule(ruleProto);

    // Retrieves and decrypts the user's refresh token from Firestore.
    final encryptedToken =
        await _firestoreClient.getEncryptedUserRefreshToken(userId);
    final refreshToken = decryptRefreshToken(encryptedToken, _aesKey);

    // Creates an authenticated client for the user using their refresh token.
    final userClient = await _googleApi.getUserAccountClient(refreshToken);

    // Creates a DV360 client using the user's authenticated client.
    final dv360 = DisplayVideo360Client(userClient, _dv360BaseUrl);

    // Runs the rule using the DV360 client.
    await rule.run(dv360);

    return Response.ok({});
  }

  /// Returns the [Rule] model form of the rule proto.
  @visibleForTesting
  Rule getRule(proto.Rule ruleProto) {
    return Rule.fromProto(ruleProto);
  }
}
