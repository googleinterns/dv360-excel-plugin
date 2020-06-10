import 'dart:js';

import 'js/gapi.dart';
import 'js/json_js.dart';
import 'package:dv360_excel_plugin/private_keys.dart';

class Credential {
  Credential._private();

  static final Credential _singleton = Credential._private();

  factory Credential() {
    return _singleton;
  }

  GoogleAuth googleAuth;
  final scope = 'https://www.googleapis.com/auth/display-video';

  void handleAuthClick() {
    if (googleAuth.isSignedIn.get()) {
      googleAuth.signOut();
    } else {
      googleAuth.signIn();
    }
  }

  void handleClientLoad() {
    load('client:auth2', allowInterop(_initClient));
  }

  void _initClient() {
    // Retrieve the discovery document for version 1 of DV360 public API.
    var discoveryUrl = 'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';

    // Initialize the gapi.client object, which app uses to make API requests.
    // Get API key and client ID from API Console.
    // 'scope' field specifies space-delimited list of access scopes.
    var initArgs = InitArgs(
        apiKey: apiKey,
        clientId: clientID,
        discoveryDocs: [discoveryUrl],
        scope: scope);

    client.init(initArgs).then(allowInterop((value) {
      print('JIN: client.init() Success');
      googleAuth = auth2.getAuthInstance();

      // Listen for sign-in state changes
      googleAuth.isSignedIn.listen(allowInterop(_updateSignInStatus));

      // Handle initial sign-in state. (Determine if user is already signed in.)
      _setSignInStatus(googleAuth.isSignedIn.get());

    }), allowInterop((error) {
      print('JIN: client.init() Error');
    }));
  }

  void _updateSignInStatus(bool isSignedIn) {
    _setSignInStatus(isSignedIn);
  }

  void _setSignInStatus(bool isSignedIn) {
    var user = googleAuth.currentUser.get();
    var isAuthorized = user.hasGrantedScopes(scope);
    if (isSignedIn && isAuthorized) {
      // User is signed in and has granted access to this app
      print('User is signed in and has granted access to this app');

      // Client request testing, will be moved to query_service.dart
      var advertiserID = '164337';
      var ioID = '8127549';
      var requestArgs = RequestArgs(
        path: 'https://displayvideo.googleapis.com/v1/advertisers/$advertiserID/insertionOrders/$ioID',
        method: 'GET'
      );

      client.request(requestArgs).then(allowInterop((response) {
        print('JIN: query request fulfilled');
        print(stringify(response.result));
      }), allowInterop((error) {
        print('JIN: query request rejected');
      }));

    } else {
      // User is signed out or has not granted access to this app
      print('User is signed out or has not granted access to this app');
    }
  }
}
