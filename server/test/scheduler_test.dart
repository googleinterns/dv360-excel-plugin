import 'package:aqueduct_test/aqueduct_test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/cloudscheduler/v1.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:server/proto/communication.pb.dart';
import 'package:server/proto/rule.pb.dart';
import 'package:server/server.dart';
import 'package:server/service/scheduler.dart';

void main() {
  const mockServerPort = 8003;
  final mockSchedulerServer = MockHTTPServer(mockServerPort);
  const url = 'http://localhost:$mockServerPort/';

  const projectId = 'test-project';
  const locationId = 'us-central1';
  const appEngineService = 'rules-server';
  const userId = 'testId123';

  final client = http.Client();
  SchedulerClient scheduler;
  Request request;
  Job job;

  final rule = Rule()
    ..name = 'My new rule'
    ..id = '123'
    ..action = (Action()
      ..type = Action_Type.CHANGE_LINE_ITEM_STATUS
      ..changeLineItemStatusParams = (ChangeLineItemStatusParams()
        ..lineItemIds.add(Int64(12345))
        ..advertiserId = Int64(67890)
        ..status = ChangeLineItemStatusParams_Status.PAUSED))
    ..schedule = (Schedule()
      ..type = Schedule_Type.REPEATING
      ..timezone = 'America/Los_Angeles'
      ..repeatingParams =
          (Schedule_RepeatingParams()..cronExpression = '* * * * *'));

  setUpAll(() async {
    await mockSchedulerServer.open();
    scheduler =
        SchedulerClient(client, projectId, locationId, appEngineService, url);
  });

  tearDownAll(() async {
    await mockSchedulerServer.close();
  });

  tearDown(() async {
    mockSchedulerServer.clear();
  });

  group('Success case: scheduleRule()', () {
    setUp(() async {
      mockSchedulerServer.queueResponse(Response.ok({}));

      await scheduler.scheduleRule(userId, rule);
      request = await mockSchedulerServer.next();

      job = Job.fromJson(await request.body.decode());
    });

    test('makes a POST request', () async {
      expect(request.method, equals('POST'));
    });

    test('makes a request that goes to the correct path', () async {
      expect(request.path.string,
          '/v1/projects/$projectId/locations/$locationId/jobs');
    });

    test('makes a request to create a job with the correct job name', () async {
      final jobName =
          'projects/$projectId/locations/$locationId/jobs/${userId}_${rule.id}';

      expect(job.name, equals(jobName));
    });

    test('makes a request to create a job with the correct App Engine service',
        () async {
      expect(job.appEngineHttpTarget.appEngineRouting.service,
          equals(appEngineService));
    });

    test('makes a request to create a job with the correct relative path',
        () async {
      expect(job.appEngineHttpTarget.relativeUri, equals(SchedulerClient.path));
    });

    test('makes a request to create a job with the correct timezone', () async {
      expect(job.timeZone, equals(rule.schedule.timezone));
    });

    test('makes a request to create a job with the correct method', () async {
      const method = 'POST';

      expect(job.appEngineHttpTarget.httpMethod, equals(method));
    });

    test('makes a request to create a job with correct headers', () async {
      final headers = {'Content-Type': 'application/x-protobuf'};

      expect(job.appEngineHttpTarget.headers, equals(headers));
    });

    test('makes a request to create a job with the correct body', () async {
      final ruleDetails = ScheduledRule()
        ..ruleId = rule.id
        ..userId = userId;

      expect(job.appEngineHttpTarget.bodyAsBytes,
          equals(ruleDetails.writeToBuffer()));
    });

    test('makes a request to create a job with the correct repeating schedule',
        () async {
      expect(
          job.schedule, equals(rule.schedule.repeatingParams.cronExpression));
    });
  });

  group('Failure case: scheduleRule()', () {
    test('throws an ApiRequestError when there is an API error', () async {
      mockSchedulerServer.queueResponse(Response.notFound());

      Future<void> actual() async => await scheduler.scheduleRule(userId, rule);

      expect(actual, throwsA(const TypeMatcher<ApiRequestError>()));
    });
  });
}
