import 'package:fixnum/fixnum.dart';
import 'package:googleapis/displayvideo/v1.dart';
import 'package:test/test.dart';
import 'package:aqueduct_test/aqueduct_test.dart';

import 'package:server/server.dart';
import 'package:server/service/dv360.dart';
import 'package:http/http.dart' as http;

void main() {
  const mockServerPort = 8001;
  final mockDisplayVideo360 = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort/';

  const status = 'ENTITY_STATUS_PAUSED';
  final advertiserId = Int64(12345);
  final lineItemId = Int64(6789);

  final client = http.Client();
  DisplayVideo360 displayVideo360;

  setUpAll(() async {
    await mockDisplayVideo360.open();
    displayVideo360 = DisplayVideo360(client, url);
  });

  tearDownAll(() async {
    await mockDisplayVideo360.close();
  });

  tearDown(() async {
    mockDisplayVideo360.clear();
  });

  group('Change Line Item Status', () {
    test('Method makes a PATCH request', () async {
      mockDisplayVideo360.queueResponse(Response.ok({}));

      await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);
      final request = await mockDisplayVideo360.next();

      expect(request.method, equals('PATCH'));
    });

    test('The request goes to the correct path', () async {
      mockDisplayVideo360.queueResponse(Response.ok({}));

      await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);
      final request = await mockDisplayVideo360.next();

      expect(request.path.string,
          '/v1/advertisers/$advertiserId/lineItems/$lineItemId');
    });

    test('The request body contains a line item with the correct entityStatus',
        () async {
      mockDisplayVideo360.queueResponse(Response.ok({}));

      await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);
      final request = await mockDisplayVideo360.next();
      final lineItem = LineItem.fromJson(await request.body.decode());

      expect(lineItem.entityStatus, equals(status));
    });

    test('The request update mask is correct', () async {
      mockDisplayVideo360.queueResponse(Response.ok({}));

      await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);
      final request = await mockDisplayVideo360.next();
      final queryParameters = request.raw.uri.queryParameters;

      expect(queryParameters['updateMask'], equals('entityStatus'));
    });

    test('On API error, throws an ApiRequestError', () async {
      mockDisplayVideo360.queueResponse(Response.notFound());

      final actual = () async => await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);

      expect(actual, throwsA(TypeMatcher<ApiRequestError>()));
    });
  });
}
