import 'dart:js';

import 'gapi.dart';
import 'private_keys.dart' as key_store;

class CredentialService {
  CredentialService._private();

  static final CredentialService _singleton = CredentialService._private();

  factory CredentialService() {
    return _singleton;
  }

  GoogleAuth _googleAuth;
  final _scope = 'https://www.googleapis.com/auth/display-video';
  final _redirectURI = 'http://localhost:8080/';

  /// Loads gapi.client library and calls [_initClient]
  /// when library finishes loading.
  void handleClientLoad() {
    GoogleAPI.load('client:auth2', allowInterop(_initClient));
  }

  /// Handles sign-in/out button clicks.
  void handleAuthClick() async {
    if (_googleAuth.isSignedIn.get()) {
      await _googleAuth.signOut();
      await _googleAuth.disconnect();
    } else {
      final arg = SignInArgs(ux_mode: 'redirect', redirect_uri: _redirectURI);
      await _googleAuth.signIn(arg);
    }
  }

  void _initClient() async {
    // Retrieve the discovery document for version 1 of DV360 public API.
    final discoveryUrl =
        'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';

    // Initializes the gapi.client object, which app uses to make API requests.
    // [apikey] and [clientId] are obtained from google api console.
    // [scope] specifies space-delimited list of access scopes.
    final initArgs = InitArgs(
        apiKey: key_store.apiKey,
        clientId: key_store.clientID,
        discoveryDocs: [discoveryUrl],
        scope: _scope);

    await GoogleAPI.client.init(initArgs).then(allowInterop((value) {
      _googleAuth = GoogleAPI.auth2.getAuthInstance();

      // Listens for sign-in state changes.
      _googleAuth.isSignedIn.listen(allowInterop(_setSignInStatus));

      // Handles initial sign-in state (check if user is already signed in).
      _setSignInStatus(_googleAuth.isSignedIn.get());
    }));
  }

  void _setSignInStatus(bool isSignedIn) async {
    final user = _googleAuth.currentUser.get();
    final isAuthorized = user.hasGrantedScopes(_scope);

    // TODO: issue created regarding components update
    //  https://github.com/DV360-spreadsheet-plugin/dv360-excel-plugin/issues/2
    if (isSignedIn && isAuthorized) {
      // User is signed in and has granted access to this app.
      // Update the page to display query components.
    } else {
      // User is signed out or has not granted access to this app.
      // Update the page to display sign-in components.
    }
  }
}
