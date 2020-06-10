@JS('gapi')
library gapi;

import 'package:js/js.dart';

/// Wrapper functions for gapi
/// Type definitions can be found at:
/// https://github.com/google/google-api-javascript-client/blob/master/docs/reference.md

/// ``` javascript function
///   gapi.load()
/// ```
@JS()
external void load(String libraries, Function callback, [Function onerror, int timeout, Function ontimeout]);

/// The client getter
/// ``` javascript object
///   gapi.client
/// ```
@JS()
external Client get client;

/// ``` javascript functions
///   gapi.client.init(args)
///   gapi.client.request(args)
/// ```
@JS('client')
class Client {
  // Client Setup
  external GoogleAuth init(InitArgs args);

  // API requests
  external Request request(RequestArgs args);
}

/// ``` javascript function
///   gapi.client.Request.then()
/// ```
@JS('client.Request')
class Request {
  external Future<dynamic> then(Function onFulfilled, [Function onRejected]);
}

/// Input argument to [Client.init()]
@JS()
@anonymous
class InitArgs {
  external String get apiKey;
  external List<String> get discoveryDocs;
  external String get clientId;
  external String get scope;

  external factory InitArgs({String apiKey, String clientId, List<String> discoveryDocs, String scope});
}

/// Input arugment to [Client.request()]
@JS()
@anonymous
class RequestArgs {
  external String get path;
  external String get method;
  external Map<String, String> get params;
  external String get headers;
  external String get body;

  external factory RequestArgs({String path, String method, Map<String, String> params, String header, String body});
}

/// The auth2 getter
/// ``` javascript object
///   gapi.auth2
/// ```
@JS('auth2')
external Auth2 get auth2;

/// ``` javascript function
///   gapi.auth2.getAuthInstance()
/// ```
@JS('auth2')
class Auth2 {
  external GoogleAuth getAuthInstance();
}

/// ``` javascript properties and functions
///   gapi.auth2.GoogleAuth.isSignedIn
///   gapi.auth2.GoogleAuth.currentUser
///   gapi.auth2.GoogleAuth.signIn()
///   gapi.auth2.GoogleAuth.signOut()
///   gapi.auth2.GoogleAuth.then()
/// ```
@JS('auth2.GoogleAuth')
class GoogleAuth {
  external IsSignedIn get isSignedIn;
  external GoogleUser get currentUser;
  external Future<dynamic> signIn();
  external Future<dynamic> signOut();
  external Future<dynamic> then(Function onInit, [Function onError]);
}

/// Input argument to [GoogleAuth.signIn()]
@JS()
@anonymous
class SignInArgs{
  external String get prompt;
  external String get scope;
  external String get ux_mode;
  external String get redirect_uri;

  external factory SignInArgs({String prompt, String scope, String ux_mode, String redirect_uri});
}

/// ``` javascript functions
///   gapi.auth2.GoogleAuth.isSignedIn.listen()
///   gapi.auth2.GoogleAuth.isSignedIn.get()
/// `
@JS('auth2.GoogleAuth.isSignedIn')
class IsSignedIn {
  external void listen(Function listener);
  external bool get();
}

/// ``` javascript functions
///   gapi.auth2.GoogleUser.get()
///   gapi.auth2.GoogleUser.hasGrantedScopes()
/// `
@JS('auth2.GoogleUser')
class GoogleUser {
  external GoogleUser get();
  external bool hasGrantedScopes(String scope);
}

