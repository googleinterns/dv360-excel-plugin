@JS('gapi')
library gapi;

import 'package:js/js.dart';

/// Type definitions for gapi
/// documentation: https://github.com/google/google-api-javascript-client/blob/master/docs/reference.md

// Invokes `gapi.load()`
@JS()
external void load(String libraries, Function callback, [Function onerror, int timeout, Function ontimeout]);

// `gapi.client` getter
@JS()
external Client get client;

// `gapi.client`
@JS('client')
class Client {
  // Client Setup
  external GoogleAuth init(InitArgs args);
  external Future<dynamic> load(String url);
  external set setApiKey(String apiKey);
  external set setToken(TokenObject tokenObject);

  // API requests
  external Future<Request> request();
}

// `gapi.client.request`
@JS('client.Request')
class Request {
  external void execute(Function callback);
}

// args to `gapi.client.init()`
@JS()
@anonymous
class InitArgs {
  external String get apiKey;
  external List<String> get discoveryDocs;
  external String get clientId;
  external String get scope;

  external factory InitArgs({String apiKey, String clientId, List<String> discoveryDocs, String scope});
}

// args to `gapi.client.request()`
@JS()
@anonymous
class RequestArgs {
  external String get path;
  external String get method;
  external Map<String, String> get params;
  external String get headers;
  external String get body;

  external factory RequestArgs();
}

// args to `gapi.client.setToken()`
@JS()
@anonymous
class TokenObject {
  external String get access_token;

  external factory TokenObject({String access_token});
}

// `gapi.auth2` getter
@JS('auth2')
external Auth2 get auth2;

// `gapi.auth2`
@JS('auth2')
class Auth2 {
  external GoogleAuth getAuthInstance();
}

// `gapi.auth2.GoogleAuth`
@JS('auth2.GoogleAuth')
class GoogleAuth {
  external Future<dynamic> then(Function onInit, [Function onError]);
  external Future<dynamic> signIn();
  external Future<dynamic> signOut();
  external IsSignedIn get isSignedIn;
  external GoogleUser get currentUser;
}

// `gapi.auth2.GoogleAuth.isSignedIn`
@JS('auth2.GoogleAuth.isSignedIn')
class IsSignedIn {
  external void listen(Function listener);
  external bool get();
}

// `gapi.auth2.GoogleUser`
@JS('auth2.GoogleUser')
class GoogleUser {
  external GoogleUser get();
  external bool hasGrantedScopes(String scope);
}

