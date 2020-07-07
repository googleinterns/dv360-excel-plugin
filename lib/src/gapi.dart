@JS()
library gapi;

import 'package:js/js.dart';

/// Below are wrapper functions for gapi APIs.
/// Type definitions can be found at
/// https://github.com/google/google-api-javascript-client/blob/master/docs/reference.md.

/// Top level JS class gapi.
///
/// ``` js
///   gapi.load()
///   gapi.client
///   gapi.auth2
/// ```
@JS('gapi')
class GoogleAPI {
  /// Loads gapi.client library.
  external static void load(String libraries, Function callback,
      [Function onerror, int timeout, Function ontimeout]);

  /// The current gapi.client instance.
  external static Client get client;

  /// The current gapi.auth2 instance.
  external static Auth2 get auth2;
}

/// Wrappers for two gapi.client functions.
///
/// ``` js
///   gapi.client.init(args)
///   gapi.client.request(args)
/// ```
@JS()
class Client {
  /// Initializes the JavaScript client with [InitArgs].
  external GoogleAuth init(InitArgs args);

  /// Creates a HTTP request with [RequestArgs] for making RESTful requests.
  external Request request(RequestArgs args);
}

/// Wrapper for gapi.client.Request function.
///
/// gapi.client.Request object implements goog.Thenable, similar to a Promise.
/// ``` js
///   gapi.client.Request.execute()
/// ```
@JS()
class Request {
  /// Executes the request and runs the supplied callback on response.
  external void execute(Function(dynamic jsonResp, dynamic rawResp) callback);
}

/// Input argument to [Client.init()].
@JS()
@anonymous
class InitArgs {
  external String get apiKey;
  external List<String> get discoveryDocs;
  external String get clientId;
  external String get scope;

  external factory InitArgs(
      {String apiKey,
      String clientId,
      List<String> discoveryDocs,
      String scope});
}

/// Input argument to [Client.request()].
@JS()
@anonymous
class RequestArgs {
  external String get path;
  external String get method;
  external Map<String, String> get params;
  external String get headers;
  external String get body;

  external factory RequestArgs(
      {String path,
      String method,
      Map<String, String> params,
      String header,
      String body});
}

/// Wrapper for gapi.auth2 function.
///
/// ``` js
///   gapi.auth2.getAuthInstance()
/// ```
@JS()
class Auth2 {
  /// Returns the GoogleAuth object.
  external GoogleAuth getAuthInstance();
}

/// Wrapper for gapi.auth2.GoogleAuth functions.
///
/// ``` js
///   gapi.auth2.GoogleAuth.isSignedIn
///   gapi.auth2.GoogleAuth.currentUser
///   gapi.auth2.GoogleAuth.signIn()
///   gapi.auth2.GoogleAuth.signOut()
///   gapi.auth2.GoogleAuth.then()
/// ```
@JS()
class GoogleAuth {
  /// The current gapi.auth2.GoogleAuth.isSignedIn object.
  external IsSignedIn get isSignedIn;

  /// The current gapi.auth2.GoogleAuth.currentUser object.
  external GoogleUser get currentUser;

  /// Signs in the user with the options specified to gapi.auth2.init().
  external Future<dynamic> signIn([SignInArgs args]);

  /// Signs out the current account from the application.
  external Future<dynamic> signOut();

  /// Revokes all of the scopes that the user granted.
  external void disconnect();

  /// Calls the onInit function when the GoogleAuth object is fully initialized.
  external Future<dynamic> then(Function onInit, [Function onError]);
}

/// Input argument to [GoogleAuth.signIn()].
@JS()
@anonymous
class SignInArgs {
  external String get prompt;
  external String get scope;
  external String get ux_mode;
  external String get redirect_uri;

  external factory SignInArgs(
      {String prompt, String scope, String ux_mode, String redirect_uri});
}

/// Wrapper for gapi.auth2.GoogleAuth.isSignedIn functions.
///
/// ``` js
///   gapi.auth2.GoogleAuth.isSignedIn.listen()
///   gapi.auth2.GoogleAuth.isSignedIn.get()
/// ```
@JS()
class IsSignedIn {
  /// Listens for changes in the current user's sign-in state.
  external void listen(Function listener);

  /// Returns `true` if the user is currently signed in.
  external bool get();
}

/// Wrapper for gapi.auth2.GoogleUser functions.
///
/// ``` js
///   gapi.auth2.GoogleUser.get()
///   gapi.auth2.GoogleUser.hasGrantedScopes()
/// ```
@JS()
class GoogleUser {
  /// Returns a GoogleUser object that represents the current user.
  external GoogleUser get();

  /// Returns `true` if the user granted the specified scopes.
  external bool hasGrantedScopes(String scope);
}
