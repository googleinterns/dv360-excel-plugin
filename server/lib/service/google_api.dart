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

  /// The scopes the user account client needs to access the ID token and
  /// DV360 API.
  static const List<String> userAccountScope = [
    'openid email',
    'https://www.googleapis.com/auth/display-video',
  ];

  /// The client ID for OAuth2.
  final String _clientId;

  /// The client secret for OAuth2.
  final String _clientSecret;

  /// Creates an instance of [GoogleApi] with a client ID and secret.
  GoogleApi(this._clientId, this._clientSecret);

  /// Creates an [AutoRefreshingAuthClient] for the service account.
  ///
  /// Locally, we use the JSON file generated using the following command:
  /// ```
  /// gcloud auth application-default login
  /// ```
  /// On AppEngine, the service account is used.
  Future<AutoRefreshingAuthClient> getServiceAccountClient() async {
    return clientViaApplicationDefaultCredentials(scopes: serviceAccountScope);
  }

  /// Creates an [AutoRefreshingAuthClient] for the user account with a refresh
  /// token.
  ///
  /// This method creates a temporary expired [AccessCredentials] to force the
  /// [AutoRefreshingAuthClient] to refresh during it's next operation.
  Future<AutoRefreshingAuthClient> getUserAccountClient(
      String refreshToken) async {
    final baseClient = http.Client();

    // Create expired [AccessCredentials] so that it will be refreshed.
    final credentials = _getCredentialsFromRefreshToken(refreshToken);

    return autoRefreshingClient(
        ClientId(_clientId, _clientSecret), credentials, baseClient);
  }

  AccessCredentials _getCredentialsFromRefreshToken(String refreshToken) {
    // Create an [AccessToken] that expired on the Unix epoch
    final expiredToken = AccessToken(
        'Bearer', '', DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true));

    return AccessCredentials(expiredToken, refreshToken, userAccountScope);
  }
}