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

  /// Duplicates the line item to destination.
  ///
  /// Throws an [ApiRequestError] if API returns an error.
  Future<void> duplicateLineItem(Int64 advertiserId, Int64 lineItemId,
      Int64 advertiserIdDestination, Int64 insertionOrderIdDestination) async {
    final source = await _api.advertisers.lineItems
        .get(advertiserId.toString(), lineItemId.toString());

    // Stores the current entity status because only ENTITY_STATUS_DRAFT is
    // allowed at creation.
    final currentStatus = source.entityStatus;

    // Sets the correct fields for line item creation.
    // Inherits flight dates from the destination parent insertion order.
    source
      ..insertionOrderId = insertionOrderIdDestination.toString()
      ..entityStatus = 'ENTITY_STATUS_DRAFT'
      ..advertiserId = null
      ..campaignId = null
      ..lineItemId = null
      ..updateTime = null
      ..partnerCosts = null
      ..name = null
      ..flight.dateRange = null
      ..flight.flightDateType = 'LINE_ITEM_FLIGHT_DATE_TYPE_INHERITED';

    // Duplicates the line item.
    final duplicate = await _api.advertisers.lineItems
        .create(source, advertiserIdDestination.toString());

    // Matches the new line item's current status to the old status.
    await changeLineItemStatus(Int64.parseInt(duplicate.advertiserId),
        Int64.parseInt(duplicate.lineItemId), currentStatus);
  }

  /// Runs the rule to manipulate DV360 line items and logs the result.
  Future<void> run(Rule rule, String userId, String ruleId) async {
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
        // security issues if we just directly report the raw exception messages.
        return await _firestoreClient.logRunHistory(userId, ruleId, false,
            message: 'Internal error encountered');
      }
      // Logs the successful run of the rule.
      await _firestoreClient.logRunHistory(userId, ruleId, true);
    }
  }
}
