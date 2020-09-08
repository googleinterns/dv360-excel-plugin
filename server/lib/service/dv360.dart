import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:googleapis/displayvideo/v1.dart';
import 'package:http/http.dart';

import '../model/rule.dart';
import '../service/firestore.dart';

/// A class that wraps around Display & Video 360.
class DisplayVideo360Client {
  /// The DV360 API.
  final DisplayvideoApi _api;

  /// The Firestore client.
  final FirestoreClient _firestoreClient;

  /// Creates an instance of [DisplayVideo360Client].
  DisplayVideo360Client(Client client, this._firestoreClient, String baseUrl)
      : _api = DisplayvideoApi(client, rootUrl: baseUrl);

  /// Changes the entity status of the line item to [status].
  ///
  /// [status] can be "ENTITY_STATUS_ACTIVE" or "ENTITY_STATUS_PAUSED".
  /// Throws an [ApiRequestError] if API returns an error.
  Future<void> changeLineItemStatus(
      Int64 advertiserId, Int64 lineItemId, String status) async {
    final request = LineItem()..entityStatus = status;
    await _api.advertisers.lineItems.patch(
        request, advertiserId.toString(), lineItemId.toString(),
        updateMask: 'entityStatus');
  }

  /// Runs the rule to manipulate DV360 line items and logs the result.
  Future<void> run(Rule rule, String userId, String ruleId) async {
    // If the rule is one-time and the year doesn't match, do not run the rule.
    // Cloud Scheduler uses cron expressions that do not specify the year.
    if (!rule.isRepeating && rule.year != DateTime.now().year) {
      return;
    }

    for (final target in rule.scope.targets) {
      try {
        await rule.action.run(this, target);
      } on ApiRequestError catch (e) {
        // If there is an API error, return the message returned by the API.
        return await _firestoreClient.logRunHistory(userId, ruleId, false,
            message: e.message);
      } catch (e) {
        // If there is another kind of exception, do not include the message.
        //
        // The messages we log should be user-friendly, actionable and
        // understandable. We can expect this for DV360 API error messages, but
        // probably not for lower level exception messages. Also, there might be
        // security issues if we directly report the raw exception messages.
        return await _firestoreClient.logRunHistory(userId, ruleId, false,
            message: 'Internal error encountered');
      }
      // Logs the successful run of the rule.
      await _firestoreClient.logRunHistory(userId, ruleId, true);
    }
  }
}
