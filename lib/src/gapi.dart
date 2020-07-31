@JS()
library gapi;

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:js/js.dart';

import 'google_api_request_args.dart';
import 'json_js.dart';

/// Below are wrapper functions for gapi APIs.
/// Type definitions can be found at
/// https://github.com/google/google-api-javascript-client/blob/master/docs/reference.md.

@Injectable()
class GoogleApiDart {
  /// Loads the Google API javascript library.
  ///
  /// Uses [Completer] to turn callback function into [Future].
  Future<void> loadLibrary(String library) {
    final completer = Completer<void>();
    GoogleAPI.load(library, allowInterop(() => completer.complete()));
    return completer.future;
  }

  /// Initializes the [GoogleAPI.auth] object and calls [callback] that returns
  /// the current sign-in status.
  ///
  /// This function must be called before calling any [Auth2] methods.
  /// Uses [Completer] to turn turn callback function into [Future].
  Future<bool> initClient(String apiKey, String clientId,
      List<String> discoveryDocs, String scope, bool Function() callback) {
    final initArgs = InitArgsJs(
        apiKey: apiKey,
        clientId: clientId,
        discoveryDocs: discoveryDocs,
        scope: scope);

    final completer = Completer<bool>();
    GoogleAPI.client
        .init(initArgs)
        .then(allowInterop((_) => completer.complete(callback())));

    return completer.future;
  }

  /// Gets the current sign-in status.
  bool getSignInStatus() => GoogleAPI.auth2.getAuthInstance().isSignedIn.get();

  /// Signs in the user using the specific [SignInArgsJs].
  ///
  /// Uses [Completer] to turn callback function of [JsPromise] into [Future].
  Future<void> signIn(String uxMode, String redirectUri) {
    final completer = Completer<void>();
    GoogleAPI.auth2
        .getAuthInstance()
        .signIn(SignInArgsJs(ux_mode: uxMode, redirect_uri: redirectUri))
        .then(allowInterop((_) => completer.complete()));
    return completer.future;
  }

  /// Signs out the current account from the application, and
  /// revokes all of the scopes that the user granted.
  ///
  /// Uses [Completer] to turn callback function of [JsPromise] into [Future].
  Future<void> signOut() {
    final completer = Completer<void>();
    final googleAuth = GoogleAPI.auth2.getAuthInstance();
    googleAuth.signOut().then(allowInterop((_) => completer.complete()));
    googleAuth.disconnect();
    return completer.future;
  }

  /// Executes the request specified by [RequestArgsJs] and returns the response
  /// parsed as a json string.
  ///
  /// Uses [Completer] to turn callback function into [Future].
  /// [jsonResp] contains the response parsed as a javascript json object.
  /// If the response is not JSON, this field will be false, and [rawResp]
  /// is the HTTP response.
  Future<String> request(GoogleApiRequestArgs args) {
    final requestArgsJs =
        RequestArgsJs(path: args.path, method: args.method, body: args.body);

    final completer = Completer<String>();
    GoogleAPI.client
        .request(requestArgsJs)
        .execute(allowInterop((jsonResp, rawResp) {
      if (jsonResp == false) {
        return completer.complete(rawResp);
      } else {
        return completer.complete(JsonJS.stringify(jsonResp));
      }
    }));
    return completer.future;
  }
}

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
  /// Initializes the JavaScript client with [InitArgsJs].
  external GoogleAuth init(InitArgsJs args);

  /// Creates a HTTP request with [RequestArgsJs] for making RESTful requests.
  external Request request(RequestArgsJs args);
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
class InitArgsJs {
  external String get apiKey;
  external List<String> get discoveryDocs;
  external String get clientId;
  external String get scope;

  external factory InitArgsJs(
      {String apiKey,
      String clientId,
      List<String> discoveryDocs,
      String scope});
}

/// Input argument to [Client.request()].
@JS()
@anonymous
class RequestArgsJs {
  external String get path;
  external String get method;
  external Map<String, String> get params;
  external String get headers;
  external String get body;

  external factory RequestArgsJs(
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
  external JsPromise signIn([SignInArgsJs args]);

  /// Signs out the current account from the application.
  external JsPromise signOut();

  /// Revokes all of the scopes that the user granted.
  external void disconnect();

  /// Calls the onInit function when the GoogleAuth object is fully initialized.
  external void then(Function onInit, [Function onError]);
}

/// Wrapper class for javascript Promise class.
///
/// ``` js
///   Promise.then()
/// ```
@JS()
class JsPromise {
  external JsPromise then(dynamic Function(dynamic value) fulfilled,
      [dynamic Function(dynamic reason) rejected]);
}

/// Input argument to [GoogleAuth.signIn()].
@JS()
@anonymous
class SignInArgsJs {
  external String get prompt;
  external String get scope;
  external String get ux_mode;
  external String get redirect_uri;

  external factory SignInArgsJs(
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
