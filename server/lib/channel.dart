import 'package:http/http.dart' as http;

import 'controller/id_token_validator.dart';
import 'controller/rule_controller.dart';
import 'controller/run_rule_controller.dart';
import 'controller/user_controller.dart';
import 'server.dart';
import 'service/firestore.dart';
import 'service/google_api.dart';
import 'service/scheduler.dart';

/// A subclass of [ApplicationChannel] that is created for each isolate.
class ServerChannel extends ApplicationChannel {
  /// The [GoogleApi] instance that provides authenticated clients to access
  /// Google APIs.
  GoogleApi googleApi;

  /// The authenticated client for the service account.
  http.Client serviceAccountClient;

  /// The client to interact with Firestore.
  FirestoreClient firestoreClient;

  /// The client to interact with Scheduler.
  SchedulerClient schedulerClient;

  /// The AES key to encode/decode refresh tokens.
  String aesKey;

  /// The configuration settings for the server.
  ServerConfiguration configuration;

  /// Initializes logger, configuration values, and services to be injected.
  @override
  Future prepare() async {
    // Record stack traces if level is severe or higher.
    recordStackTraceAtLevel = Level.SEVERE;
    logger.onRecord.listen((final record) {
      print(record);
      print(record.error ?? '');
      print(record.stackTrace ?? '');
    });
    // Uncomment for stack trace in response.
    // Controller.includeErrorDetailsInServerErrorResponses = true;

    configuration = ServerConfiguration(options.configurationFilePath);
    aesKey = configuration.refreshTokenKey;

    // Initialize services.
    googleApi = GoogleApi(configuration.clientId, configuration.clientSecret);
    serviceAccountClient = await googleApi.getServiceAccountClient();
    firestoreClient = FirestoreClient(
        serviceAccountClient,
        configuration.projectId,
        configuration.databaseId,
        configuration.firestore.baseURL);
    schedulerClient = SchedulerClient(
        serviceAccountClient,
        configuration.projectId,
        configuration.locationId,
        configuration.appEngineService,
        configuration.scheduler.baseURL);
  }

  /// Gets the entry point controller.
  @override
  Controller get entryPoint {
    final router = Router();

    router
        .route('/users')
        .link(() => IdTokenValidator())
        .link(() => UserController(firestoreClient, aesKey));

    router
        .route('/rules')
        .link(() => IdTokenValidator())
        .link(() => RuleController(firestoreClient, schedulerClient));

    router.route('/run_rule').link(() => RunRuleController(googleApi,
        firestoreClient, aesKey, configuration.displayVideo360.baseURL));

    return router;
  }
}

/// A class that represents the configuration settings of the server.
class ServerConfiguration extends Configuration {
  String clientId;
  String clientSecret;
  String projectId;
  String databaseId;
  String locationId;
  String appEngineService;
  String refreshTokenKey;
  String googleKeysUrl;

  APIConfiguration displayVideo360;
  APIConfiguration firestore;
  APIConfiguration scheduler;

  ServerConfiguration(String path) : super.fromFile(File(path));
}
