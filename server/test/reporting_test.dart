import 'dart:async';
import 'dart:convert';

import 'package:aqueduct/aqueduct.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/doubleclickbidmanager/v1_1.dart' as reporting;
import 'package:server/service/reporting.dart';
import 'package:test/test.dart';
import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const mockServerPort = 8006;
  final mockReportingServer = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort/';
  const reportPath = 'report';
  const reportUrl = '$url$reportPath';

  final advertiserId = Int64(12345);
  final lineItemId = Int64(6789);
  const queryId = '12345678';
  const cpm = 123.45;

  final client = http.Client();
  ReportingClient reportingClient;
  Request createQueryRequest;
  Request getQueryRequest;
  Request getReportRequest;
  double returnValue;

  final createRequestBody = reporting.Query()
    ..metadata = (reporting.QueryMetadata()
      ..title = 'LineItemQuery'
      ..format = 'CSV'
      ..dataRange = 'PREVIOUS_DAY')
    ..params = (reporting.Parameters()
      ..metrics = ['METRIC_REVENUE_ECPM_ADVERTISER']
      ..groupBys = [
        'FILTER_LINE_ITEM',
        'FILTER_DATE',
        'FILTER_ADVERTISER_CURRENCY'
      ]
      ..filters = [
        (reporting.FilterPair()
          ..type = 'FILTER_ADVERTISER'
          ..value = advertiserId.toString()),
        (reporting.FilterPair()
          ..type = 'FILTER_LINE_ITEM'
          ..value = lineItemId.toString())
      ]);

  final createQueryResponse = reporting.Query()..queryId = queryId;
  final getQueryResponse = reporting.Query()
    ..metadata = (reporting.QueryMetadata()
      ..googleCloudStoragePathForLatestReport = reportUrl);

  final report = 'Line Item ID,Date,Advertiser Currency,Revenue eCPM '
      '(Adv Currency)\n$lineItemId,2020/01/01,USD,$cpm\n';
  const invalidReport = 'Line Item ID,Date,Advertiser Currency,Revenue eCPM '
      '(Adv Currency)\n\nNo data returned by the reporting service.';

  setUpAll(() async {
    await mockReportingServer.open();
    reportingClient = ReportingClient(client, url);
  });

  tearDownAll(() async {
    await mockReportingServer.close();
  });

  tearDown(() async {
    mockReportingServer.clear();
  });

  group('Success case: getLineItemCpm()', () {
    setUp(() async {
      // Responds to the create query request with a [Query] containing the id.
      mockReportingServer
          .queueResponse(Response.ok(createQueryResponse.toJson()));

      // Responds to the get query request with a [Query] containing the url.
      mockReportingServer.queueResponse(Response.ok(getQueryResponse.toJson()));

      // Responds to the get report request with the report.
      mockReportingServer.queueResponse(
          Response.ok(report, headers: {'content-type': 'text/csv'}));

      returnValue =
          await reportingClient.getLineItemCpm(advertiserId, lineItemId);

      // Gets the requests sent by the client.
      createQueryRequest = await mockReportingServer.next();
      getQueryRequest = await mockReportingServer.next();
      getReportRequest = await mockReportingServer.next();
    });

    test('makes a POST request to create the query', () async {
      expect(createQueryRequest.method, equals('POST'));
    });

    test('makes a request to the correct path to create the query', () async {
      expect(
          createQueryRequest.path.string, '/doubleclickbidmanager/v1.1/query');
    });

    test('makes a request with the correct body to create the query', () async {
      final body = json.encode(await createQueryRequest.body.decode());
      final expected = json.encode(createRequestBody);

      expect(body, equals(expected));
    });

    test('makes a POST request after to get the query', () async {
      expect(getQueryRequest.method, equals('GET'));
    });

    test('makes a request to the correct path to get the query', () async {
      expect(getQueryRequest.path.string,
          '/doubleclickbidmanager/v1.1/query/$queryId');
    });

    test('makes a request with no body to get the query', () async {
      final body = await getQueryRequest.body.decode();

      expect(body, isNull);
    });

    test('makes a GET request after to get the report', () async {
      expect(getReportRequest.method, equals('GET'));
    });

    test('makes a request to the correct path to get the query', () async {
      expect(getReportRequest.path.string, '/$reportPath');
    });

    test('returns the correct CPM value', () async {
      expect(returnValue, equals(cpm));
    });
  });

  group('Failure case: getLineItemCpm()', () {
    test('throws an ApiRequestError if error creating the query', () async {
      mockReportingServer.queueResponse(Response.serverError());

      Future<void> actual() async =>
          await reportingClient.getLineItemCpm(advertiserId, lineItemId);

      expect(actual, throwsA(const TypeMatcher<reporting.ApiRequestError>()));
    });

    test('throws an ApiRequestError if error getting the query', () async {
      mockReportingServer
          .queueResponse(Response.ok(createQueryResponse.toJson()));
      mockReportingServer.queueResponse(Response.serverError());

      Future<void> actual() async =>
          await reportingClient.getLineItemCpm(advertiserId, lineItemId);

      expect(actual, throwsA(const TypeMatcher<reporting.ApiRequestError>()));
    });

    test('throws an ArgumentError when the report is not found', () async {
      mockReportingServer
          .queueResponse(Response.ok(createQueryResponse.toJson()));
      mockReportingServer.queueResponse(Response.ok(getQueryResponse.toJson()));
      mockReportingServer.queueResponse(Response.notFound());

      Future<void> actual() async =>
          await reportingClient.getLineItemCpm(advertiserId, lineItemId);

      expect(actual, throwsA(const TypeMatcher<ArgumentError>()));
    });

    test('throws an ArgumentError when there report is missing data', () async {
      mockReportingServer
          .queueResponse(Response.ok(createQueryResponse.toJson()));
      mockReportingServer.queueResponse(Response.ok(getQueryResponse.toJson()));
      mockReportingServer.queueResponse(
          Response.ok(invalidReport, headers: {'content-type': 'text/csv'}));

      Future<void> actual() async =>
          await reportingClient.getLineItemCpm(advertiserId, lineItemId);

      expect(actual, throwsA(const TypeMatcher<ArgumentError>()));
    });
  });
}
