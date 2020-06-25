@JS()
library office;

import 'package:js/js.dart';

/// Below are wrapper functions for Office common APIs.
/// Type definitions can be found at
/// https://docs.microsoft.com/en-us/javascript/api/office?view=excel-js-preview.

/// Top level JS class Office.
///
/// ``` js
///   Office.onReady()
///   Office.Context
///   Office.AsyncResultStatus
/// ```
@JS('Office')
class Office {
  /// Ensures that the Office JS APIs are ready to be called by the add-in.
  external static Future<Info> onReady(dynamic Function(Info) callback);

  /// The runtime environment of the add-in.
  external static Context get context;

  /// The result of an asynchronous call.
  external static AsyncResultStatus get asyncResultStatus;
}

/// Input argument to [onReady()].
@JS()
@anonymous
class Info {
  external HostType get host;
  external PlatformType get platform;

  external factory Info({HostType host, PlatformType platform});
}

/// Wrapper for Office.HostType enum.
///
/// ``` js
///   Office.HostType
/// ```
@JS()
class HostType {
  external String get Access;
  external String get Excel;
  external String get OneNote;
  external String get Outlook;
  external String get PowerPoint;
  external String get Project;
  external String get Word;

  external factory HostType();
}

/// Wrapper for Office.PlatformType enum.
///
/// ``` js
///   Office.PlatformType
/// ```
@JS()
class PlatformType {
  external factory PlatformType();
}

/// Wrapper for Office.Context class.
///
/// ``` js
///   Office.Context
/// ```
@JS()
class Context {
  /// Provides objects and methods that can be used to create dialog boxes.
  external UI get ui;
}

/// Wrapper for Office.UI class.
///
/// ``` js
///   Office.UI
/// ```
@JS()
class UI {
  /// Displays a dialog box.
  external void displayDialogAsync(
      String address, [DialogOptions options, Function(AsyncResult) callback]);
}

/// Input argument to [UI.displayDialogAsync()].
@JS()
@anonymous
class DialogOptions {
  external dynamic get asyncContext;
  external bool get displayInIframe;
  external bool get promptBeforeOpen;
  external int get height;
  external int get width;

  external factory DialogOptions(
      {dynamic asyncContext,
        bool displayInIframe,
        bool promptBeforeOpen,
        int height,
        int width});
}

/// Wrapper for Office.AsyncResult interface.
///
/// ``` js
///   Office.AsyncResult
/// ```
@JS()
class AsyncResult {
  /// The object passed to the optional asyncContext parameter
  /// of the invoked method.
  external dynamic get asyncContext;

  /// The additional information if error occurs.
  external dynamic get diagnostics;

  /// The specific information about an error that occurred
  /// during an asynchronous operation.
  external OfficeError get error;

  /// The result of an asynchronous call.
  external AsyncResultStatus get status;

  /// The payload or content of the asynchronous operation, if any.
  external dynamic get value;
}

/// Wrapper for Office.Error class.
///
/// ``` js
///   Office.Error
/// ```
@JS()
class OfficeError {
  /// The numeric code of the error.
  external int get code;

  /// The name of the error.
  external String get name;

  /// Tje detailed description of the error.
  external String get message;
}

/// Wrapper for Office.AsyncResultStatus enum.
///
/// ``` JS
///   Office.AsyncResultStatus
/// ```
@JS()
class AsyncResultStatus {
  /// The asynchronous failed.
  /// 'Failed" is capitalized to match exactly to the JS function call.
  external dynamic get Failed;

  /// The asynchronous succeeded.
  /// 'Succeeded" is capitalized to match exactly to the JS function call.
  external dynamic get Succeeded;
}

/// Wrapper for Office.Dialog interface
///
/// ``` JS
///   Office.Dialog
/// ```
@JS()
class Dialog {}
