import 'server.dart';
import 'service/google_api.dart';

/// A subclass of [ApplicationChannel] that is created for each isolate.
class ServerChannel extends ApplicationChannel {
  /// The [GoogleApi] instance that provides authenticated clients to access
  /// Google APIs.
  GoogleApi googleApi;

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

    // Initialize services.
    googleApi = GoogleApi(configuration.clientId, configuration.clientSecret);
  }

  @override
  Controller get entryPoint {
    final router = Router();
    return router;
  }
}

class ServerConfiguration extends Configuration {
  String clientId;
  String clientSecret;
  String projectId;
  String databaseId;
  String locationId;
  String appEngineService;
  String googleKeysUrl;

  APIConfiguration displayVideo360;
  APIConfiguration firestore;
  APIConfiguration scheduler;

  ServerConfiguration(String path) : super.fromFile(File(path));
}
