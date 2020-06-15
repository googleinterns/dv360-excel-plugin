@JS()
library office;

import 'package:js/js.dart';

/// Wrapper functions Office common APIs
/// Type definitions can be found at:
/// https://docs.microsoft.com/en-us/javascript/api/office?view=excel-js-preview

/// Top level JS class Office
///
/// ``` js
///   Office.onReady()
/// ```
@JS('Office')
class Office {
  external static Future<Info> onReady(dynamic Function(Info) callback);
}

/// Input argument to [onReady()]
@JS()
@anonymous
class Info {
  external HostType get host;
  external PlatformType get platform;

  external factory Info({HostType host, PlatformType platform});
}

/// Wrapper for Office.HostType enum
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

/// Wrapper for Office.PlatformType enum
///
/// ``` js
///   Office.PlatformType
/// ```
@JS()
class PlatformType {
  external factory PlatformType();
}
