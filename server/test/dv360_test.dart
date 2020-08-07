import 'package:fixnum/fixnum.dart';
import 'package:googleapis/displayvideo/v1.dart';
import 'package:test/test.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:http/http.dart' as http;

import 'package:server/server.dart';
import 'package:server/service/dv360.dart';

void main() {
  const mockServerPort = 8001;
  final mockDisplayVideo360Server = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort/';

  const status = 'ENTITY_STATUS_PAUSED';
  final advertiserId = Int64(12345);
  final lineItemId = Int64(6789);

  final client = http.Client();
  DisplayVideo360Client displayVideo360;

  Request request;

  setUpAll(() async {
    await mockDisplayVideo360Server.open();
    displayVideo360 = DisplayVideo360Client(client, url);
  });

  tearDownAll(() async {
    await mockDisplayVideo360Server.close();
  });

  tearDown(() async {
    mockDisplayVideo360Server.clear();
  });

  group('Success case: changeLineItemStatus()', () {
    setUp(() async {
      mockDisplayVideo360Server.queueResponse(Response.ok({}));

      await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);
      request = await mockDisplayVideo360Server.next();
    });

    test('makes a PATCH request', () async {
      expect(request.method, equals('PATCH'));
    });

    test('makes a request that goes to the correct path', () async {
      expect(request.path.string,
          '/v1/advertisers/$advertiserId/lineItems/$lineItemId');
    });

    test(
        'makes a request with a body that contains a line item '
            'with the correct entityStatus',
        () async {
      final lineItem = LineItem.fromJson(await request.body.decode());

      expect(lineItem.entityStatus, equals(status));
    });

    test('makes a request with a correct update mask', () async {
      final queryParameters = request.raw.uri.queryParameters;

      expect(queryParameters['updateMask'], equals('entityStatus'));
    });
  });

  group('Failure case: changeLineItemStatus()', () {
    test('throws an ApiRequestError when there is an API error', () async {
      mockDisplayVideo360Server.queueResponse(Response.notFound());

      Future<void> actual() async => await displayVideo360.changeLineItemStatus(
          advertiserId, lineItemId, status);

      expect(actual, throwsA(const TypeMatcher<ApiRequestError>()));
    });
  });
}
