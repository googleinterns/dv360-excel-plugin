import 'dart:js';
import 'package:dv360_excel_plugin/js/gapi.dart';
import 'package:dv360_excel_plugin/private_keys.dart';

class Credential {
  Credential._private();

  static final Credential _singleton = Credential._private();

  factory Credential() {
    return _singleton;
  }

  var googleAuth;
  final scope = 'https://www.googleapis.com/auth/display-video';

  void handleAuthClick() {
    if (googleAuth.isSignedIn.get()) {
      googleAuth.signOut();
    } else {
      googleAuth.signIn();
    }
  }

  void handleClientLoad() {
    print('JIN: reach function handleClientLoad()');
    load('client:auth2', allowInterop(initClient));
  }

  void initClient() {
    // Retrieve the discovery document for version 1 of DV360 public API.
    var discoveryUrl =
        'https://displayvideo.googleapis.com/\$discovery/rest?version=v1';

    // Initialize the gapi.client object, which app uses to make API requests.
    // Get API key and client ID from API Console.
    // 'scope' field specifies space-delimited list of access scopes.
    var initArgs = InitArgs(
        apiKey: apiKey,
        clientId: clientID,
        discoveryDocs: [discoveryUrl],
        scope: scope);

    client.init(initArgs).then(allowInterop((value) {
      print('JIN: client.init Success');
      googleAuth = auth2.getAuthInstance();
      // Listen for sign-in state changes
      googleAuth.isSignedIn.listen(allowInterop(updateSignInStatus));
      // Handle initial sign-in state. (Determine if user is already signed in.)
      setSignInStatus();
    }), allowInterop((error) {
      print('JIN: client.init Error');
    }));
  }

  void updateSignInStatus() {
    setSignInStatus();
  }

  void setSignInStatus() {
    var user = googleAuth.currentUser.get();
    var isAuthorized = user.hasGrantedScopes(scope);
    if (isAuthorized) {
      // User is signed in and has granted access to this app
      print('User is signed in and has granted access to this app');
    } else {
      // User is signed out or has not granted access to this app
      print('User is signed out or has not granted access to this app');
    }
  }
}
