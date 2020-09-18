import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:proto/get_rules_response.pb.dart';
import 'package:proto/rule.pb.dart';

import '../service/firestore.dart';
import '../service/scheduler.dart';
import '../utils.dart';

/// A controller that handles operations on rules.
class RuleController extends ResourceController {
  /// The client that interacts with Cloud Firestore.
  final FirestoreClient _firestoreClient;

  /// The client that interacts with Cloud Scheduler.
  final SchedulerClient _schedulerClient;

  /// Creates an instance of [RuleController].
  RuleController(this._firestoreClient, this._schedulerClient);

  /// The accepted content types for this controller.
  @override
  List<ContentType> acceptedContentTypes = [
    ContentType('application', 'x-protobuf')
  ];

  /// Adds the rule to Firestore and schedules it using Scheduler.
  ///
  /// Throws [ArgumentError] if request doesn't contain an Authorization header.
  /// Throws an [ApiRequestError] if Firestore API or Scheduler API returns an
  /// error. Returns an OK 200 response upon success.
  @Operation.post()
  Future<Response> createRule(@Bind.body() List<int> body) async {
    // The ID token is sent in the `Authorization` header of the request.
    final authorizationHeader = request.raw.headers.value('Authorization');
    if (authorizationHeader == null) {
      throw ArgumentError('Request does not contain an Authorization header');
    }
    final idToken = authorizationHeader.split(' ').last;

    final userId = getUserId(idToken);
    final rule = Rule.fromBuffer(body);
    final ruleId = await _firestoreClient.createRule(userId, rule);

    // Sets the [rule.id] because the rule's ID is generated by Firestore.
    rule.id = ruleId;

    await _schedulerClient.scheduleRule(userId, rule);

    return Response.ok({});
  }

  /// Retrieves the user's rules from Firestore.
  ///
  /// Throws an [ArgumentError] if request doesn't contain an Authorization
  /// header. Throws an [ApiRequestError] if Firestore API returns an API error.
  /// Returns an OK 200 response upon success.
  @Operation.get()
  Future<Response> getRules() async {
    // The ID token is sent in the `Authorization` header of the request.
    final authorizationHeader = request.raw.headers.value('Authorization');
    if (authorizationHeader == null) {
      throw ArgumentError('Request does not contain an Authorization header');
    }
    final idToken = authorizationHeader.split(' ').last;

    final userId = getUserId(idToken);
    final rules = await _firestoreClient.getUserRules(userId);

    final response = GetRulesResponse()..rules.addAll(rules);

    return Response.ok(response.writeToBuffer())..encodeBody = false;
  }
}
