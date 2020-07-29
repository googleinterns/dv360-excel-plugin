import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';

import 'gapi.dart';
import 'private_keys.dart' as key_store;

@Injectable()
class CredentialService {
  static GoogleAuth _googleAuth;
  static const _redirectURI = 'http://localhost:8080';

  static const _dv3Scope = 'https://www.googleapis.com/auth/display-video';
  static const _dbmScope =
      'https://www.googleapis.com/auth/doubleclickbidmanager';
  static const _googleStorageScope =
      'https://www.googleapis.com/auth/devstorage.read_only';
  static const _scope = '$_dv3Scope $_dbmScope $_googleStorageScope';

  static const _dv3DiscoveryUrl =
      'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';
  static const _dbmDiscoveryUrl =
      'https://content.googleapis.com/discovery/v1/apis/doubleclickbidmanager/v1.1/rest';

  /// Loads gapi.client library.
  ///
  /// Uses [Completer] to convert callback function to [Future].
  Future<void> handleClientLoad() {
    final completer = Completer<void>();
    GoogleAPI.load('client:auth2', allowInterop(() => completer.complete()));
    return completer.future;
  }

  /// Handles sign-in/out button clicks and returns the current sign-in status.
  Future<bool> handleAuthClick() {
    final completer = Completer<bool>();
    if (_googleAuth.isSignedIn.get()) {
      _googleAuth
          .signOut()
          .then(allowInterop((_) => completer.complete(false)));
      _googleAuth.disconnect();
      return completer.future;
    } else {
      final arg = SignInArgs(ux_mode: 'redirect', redirect_uri: _redirectURI);
      _googleAuth
          .signIn(arg)
          .then(allowInterop((_) => completer.complete(true)));
      return completer.future;
    }
  }

  /// Initializes the [GoogleAPI.client] object and
  /// returns the current sign-in status.
  Future<bool> initClient() {
    // [apikey] and [clientId] are obtained from google api console.
    // [scope] specifies space-delimited list of access scopes.
    final initArgs = InitArgs(
        apiKey: key_store.apiKey,
        clientId: key_store.clientID,
        discoveryDocs: [_dv3DiscoveryUrl, _dbmDiscoveryUrl],
        scope: _scope);

    final completer = Completer<bool>();
    GoogleAPI.client.init(initArgs).then(allowInterop((value) {
      _googleAuth = GoogleAPI.auth2.getAuthInstance();

      // Listens for sign-in state changes.
      _googleAuth.isSignedIn.listen(allowInterop(_setSignInStatus));

      // Handles initial sign-in state (check if user is already signed in).
      final userValidated = _setSignInStatus(_googleAuth.isSignedIn.get());
      completer.complete(userValidated);
    }));

    return completer.future;
  }

  static bool _setSignInStatus(bool isSignedIn) {
    final user = _googleAuth.currentUser.get();
    final isAuthorized = user.hasGrantedScopes(_scope);

    return isSignedIn && isAuthorized;
  }
}
