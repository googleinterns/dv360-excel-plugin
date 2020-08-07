import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:googleapis/displayvideo/v1.dart';
import 'package:http/http.dart';

/// A class that wraps around Display & Video 360.
class DisplayVideo360Client {
  /// The DV360 API.
  final DisplayvideoApi _api;

  /// Creates an instance of [DisplayVideo360Client].
  DisplayVideo360Client(Client client, String baseUrl)
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
}
