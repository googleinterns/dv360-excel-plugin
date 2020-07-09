import 'dart:js';

import 'package:angular/angular.dart';

import 'gapi.dart';
import 'private_keys.dart' as key_store;

@Injectable()
class CredentialService {
  static GoogleAuth _googleAuth;
  static const _redirectURI = 'http://localhost:8080';

  static final _dv3Scope = 'https://www.googleapis.com/auth/display-video';
  static final _dbmScope =
      'https://www.googleapis.com/auth/doubleclickbidmanager';
  static final _googleStorageScope =
      'https://www.googleapis.com/auth/devstorage.read_only';
  static final _scope = '$_dv3Scope $_dbmScope $_googleStorageScope';

  static final _dv3DiscoveryUrl =
      'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';
  static final _dbmDiscoveryUrl =
      'https://content.googleapis.com/discovery/v1/apis/doubleclickbidmanager/v1.1/rest';

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

  static void _initClient() async {
    // Initializes the gapi.client object, which app uses to make API requests.
    // [apikey] and [clientId] are obtained from google api console.
    // [scope] specifies space-delimited list of access scopes.
    final initArgs = InitArgs(
        apiKey: key_store.apiKey,
        clientId: key_store.clientID,
        discoveryDocs: [_dv3DiscoveryUrl, _dbmDiscoveryUrl],
        scope: _scope);

    await GoogleAPI.client.init(initArgs).then(allowInterop((value) {
      _googleAuth = GoogleAPI.auth2.getAuthInstance();

      // Listens for sign-in state changes.
      _googleAuth.isSignedIn.listen(allowInterop(_setSignInStatus));

      // Handles initial sign-in state (check if user is already signed in).
      _setSignInStatus(_googleAuth.isSignedIn.get());
    }));
  }

  static void _setSignInStatus(bool isSignedIn) async {
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
