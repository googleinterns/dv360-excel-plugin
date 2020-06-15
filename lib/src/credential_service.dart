import 'dart:js';

import 'gapi.dart';
import 'json_js.dart';
import 'private_keys.dart' as key_store;

class Credential {
  Credential._private();

  static final Credential _singleton = Credential._private();

  factory Credential() {
    return _singleton;
  }

  GoogleAuth _googleAuth;
  final _scope = 'https://www.googleapis.com/auth/display-video';

  /// Loads gapi.client library and calls [_initClient] when library finishes loading
  void handleClientLoad() {
    GoogleAPI.load('client:auth2', allowInterop(_initClient));
  }

  /// Handles sign-in/out button clicks
  void handleAuthClick() async {
    if (_googleAuth.isSignedIn.get()) {
      await _googleAuth.signOut();
    } else {
      await _googleAuth.signIn();
    }
  }

  void _initClient() async {
    // Retrieve the discovery document for version 1 of DV360 public API.
    final discoveryUrl =
        'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';

    // Initialize the gapi.client object, which app uses to make API requests.
    // Get API key and client ID from API Console.
    // 'scope' field specifies space-delimited list of access scopes.
    final initArgs = InitArgs(
        apiKey: key_store.apiKey,
        clientId: key_store.clientID,
        discoveryDocs: [discoveryUrl],
        scope: _scope);

    await GoogleAPI.client.init(initArgs).then(allowInterop((value) {
      _googleAuth = GoogleAPI.auth2.getAuthInstance();

      // Listen for sign-in state changes
      _googleAuth.isSignedIn.listen(allowInterop(_updateSignInStatus));

      // Handle initial sign-in state. (Determine if user is already signed in.)
      _setSignInStatus(_googleAuth.isSignedIn.get());
    }));
  }

  void _updateSignInStatus(bool isSignedIn) {
    _setSignInStatus(isSignedIn);
  }

  void _setSignInStatus(bool isSignedIn) async {
    final user = _googleAuth.currentUser.get();
    final isAuthorized = user.hasGrantedScopes(_scope);
    if (isSignedIn && isAuthorized) {
      // User is signed in and has granted access to this app
      // Update components, display query page

      // Client request testing, always request the same io
      final advertiserID = '164337';
      final ioID = '8127549';
      final requestArgs = RequestArgs(
          path:
              'https://displayvideo.googleapis.com/v1/advertisers/$advertiserID/insertionOrders/$ioID',
          method: 'GET');

      await GoogleAPI.client.request(requestArgs).then(allowInterop((response) {
        print(stringify(response.result));
      }));
    } else {
      // User is signed out or has not granted access to this app
      // Update components, display sign-in page
    }
  }
}
