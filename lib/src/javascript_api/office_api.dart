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
}

/// Input argument to [onReady()].
@JS()
@anonymous
class Info {
  external String get host;
  external String get platform;

  external factory Info({String host, String platform});
}
