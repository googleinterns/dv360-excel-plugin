import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';

import '../javascript_api/google_api.dart';
import '../private_keys.dart' as key_store;

@Injectable()
class CredentialService {
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

  final GoogleApiDart _googleAPIDart;

  CredentialService(this._googleAPIDart);

  /// Loads gapi.client library.
  ///
  /// Uses [Completer] to convert callback function to [Future].
  Future<void> handleClientLoad() => _googleAPIDart.loadLibrary('client:auth2');

  /// Handles sign-in/out button clicks and returns the current sign-in status.
  Future<bool> handleAuthClick() async {
    if (_googleAPIDart.getSignInStatus()) {
      await _googleAPIDart.signOut();
      return false;
    } else {
      await _googleAPIDart.signIn('redirect', _redirectURI);
      return true;
    }
  }

  /// Initializes the [GoogleAPI.client] object and
  /// returns the current sign-in status.
  Future<bool> initClient() async => _googleAPIDart.initClient(
      key_store.apiKey,
      key_store.clientID,
      [_dv3DiscoveryUrl, _dbmDiscoveryUrl],
      _scope,
      _initClientCallback);

  static bool _initClientCallback() {
    final googleAuth = GoogleAPI.auth2.getAuthInstance();

    // Listens for sign-in state changes.
    googleAuth.isSignedIn.listen(allowInterop(_setSignInStatus));

    // Handles initial sign-in state (check if user is already signed in).
    return _setSignInStatus(googleAuth.isSignedIn.get());
  }

  static bool _setSignInStatus(bool isSignedIn) {
    final user = GoogleAPI.auth2.getAuthInstance().currentUser.get();
    final isAuthorized = user.hasGrantedScopes(_scope);

    return isSignedIn && isAuthorized;
  }

  Future<Map<String, String>> obtainTokens() async {
    return await _googleAPIDart.obtainTokens(
        key_store.clientID, key_store.clientSecret, _redirectURI);
  }
}
