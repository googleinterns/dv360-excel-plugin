import 'dart:async';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// A class that provides authenticated clients to interact with Google APIs.
class GoogleApi {
  /// The scopes the service account client needs to access Cloud Scheduler
  /// and Firestore.
  static const List<String> serviceAccountScope = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/cloud-scheduler',
    'https://www.googleapis.com/auth/datastore',
  ];

  /// The scopes the user account client needs to access the DV360 API.
  static const List<String> userAccountScope = [
    'https://www.googleapis.com/auth/display-video',
  ];

  /// The client ID for OAuth2.
  final String _clientId;

  /// The client secret for OAuth2.
  final String _clientSecret;

  /// Creates an instance of [GoogleApi] with a client ID and secret.
  GoogleApi(this._clientId, this._clientSecret);

  /// Creates an [http.Client] for the service account.
  ///
  /// Locally, we use the JSON file generated using the following command:
  /// ```
  /// gcloud auth application-default login
  /// ```
  /// On AppEngine, the service account is used.
  /// We will use this client to interact with Cloud Scheduler and Firestore.
  Future<http.Client> getServiceAccountClient() async {
    return clientViaApplicationDefaultCredentials(scopes: serviceAccountScope);
  }

  /// Creates an [http.Client] for the user account with a refresh
  /// token.
  ///
  /// This method creates a temporary expired [AccessCredentials] to force the
  /// [http.Client] to refresh during it's next operation.
  /// We will use this client to interact with DV360 on the user's behalf.
  Future<http.Client> getUserAccountClient(String refreshToken) async {
    final baseClient = http.Client();

    // Create expired [AccessCredentials] so that it will be refreshed when the
    // client does the next operation.
    final expiredCredentials =
        _expiredCredentialsFromRefreshToken(refreshToken);

    return autoRefreshingClient(
        ClientId(_clientId, _clientSecret), expiredCredentials, baseClient);
  }

  AccessCredentials _expiredCredentialsFromRefreshToken(String refreshToken) {
    // Create an [AccessToken] that expired on the Unix epoch.
    final expiredToken = AccessToken(
        'Bearer', '', DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true));

    return AccessCredentials(expiredToken, refreshToken, userAccountScope);
  }
}
