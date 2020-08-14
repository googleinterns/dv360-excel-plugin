import 'package:googleapis/cloudscheduler/v1.dart';
import 'package:http/http.dart';

import '../proto/scheduled_rule.pb.dart';
import '../proto/rule.pb.dart';

/// A class that wraps around Google Cloud Scheduler.
class SchedulerClient {
  /// The targeted HTTP endpoint for each job.
  static const path = '/run_rule';

  /// The number of times the job will retry, using exponential back-off.
  static const retries = 3;

  /// The Cloud Scheduler API.
  final CloudschedulerApi _api;

  /// The location of the job.
  /// See: https://cloud.google.com/about/locations/
  final String _locationId;

  /// The Google Cloud project ID.
  final String _projectId;

  /// The name of the App Engine service where the endpoint is hosted.
  final String _appEngineService;

  /// Creates an instance of [SchedulerClient].
  SchedulerClient(Client client, this._projectId, this._locationId,
      this._appEngineService, String baseUrl)
      : _api = CloudschedulerApi(client, rootUrl: baseUrl);

  /// Schedules a rule using Cloud Scheduler.
  ///
  /// Throws an [ApiRequestError] if Scheduler API returns an error.
  Future<void> scheduleRule(String userId, Rule rule) async {
    final jobName = '${userId}_${rule.id}';
    final timezone = rule.schedule.timezone;
    const method = 'POST';
    const headers = {'Content-Type': 'application/x-protobuf'};

    // Creates a [ScheduledRule] proto that allows the server to identify which
    // rule to run when the job is triggered.
    final ruleDetails = ScheduledRule()
      ..ruleId = rule.id
      ..userId = userId;

    // Depending on the schedule type, creates the Scheduler job.
    if (rule.schedule.type == Schedule_Type.REPEATING) {
      final schedule = rule.schedule.repeatingParams.cronExpression;
      await _createJob(jobName, _appEngineService, path, schedule, method,
          headers, ruleDetails.writeToBuffer(), timezone);
    } else {
      throw UnimplementedError('${rule.schedule.type} is not implemented.');
    }
  }

  /// Creates a Cloud Scheduler job with an App Engine HTTP target.
  ///
  /// The [service] is the name of the App Engine service with a target endpoint
  /// [path]. The job will run using the schedule provided by [cronExpression],
  /// and make a request with the HTTP [method], [headers], and [body].
  ///
  /// Throws an [ApiRequestError] if Scheduler API returns an error.
  Future<void> _createJob(
      String name,
      String service,
      String path,
      String cronExpression,
      String method,
      Map<String, String> headers,
      List<int> body,
      String timezone) async {
    final parent = 'projects/$_projectId/locations/$_locationId';
    final job = Job()
      ..name = '$parent/jobs/$name'
      ..appEngineHttpTarget = (AppEngineHttpTarget()
        ..appEngineRouting = (AppEngineRouting()..service = service)
        ..relativeUri = path
        ..headers = headers
        ..httpMethod = method
        ..bodyAsBytes = body)
      ..schedule = cronExpression
      ..retryConfig = (RetryConfig()..retryCount = retries)
      ..timeZone = timezone;

    await _api.projects.locations.jobs.create(job, parent);
  }
}
