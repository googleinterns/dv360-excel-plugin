@JS('Office')
library office;
import 'package:js/js.dart';

/// Type definitions for Office common APIs
/// documentation: https://docs.microsoft.com/en-us/javascript/api/office?view=excel-js-preview

// Invokes `Office.onReady()`
@JS('onReady')
external Future<Info> onReady(dynamic Function(Info) callback);

// Represents the info argument to Office.onReady()
// info: { host: HostType, platform: PlatformType }
@JS()
@anonymous
class Info {
  external HostType get host;
  external PlatformType get platform;

  external factory Info({HostType host, PlatformType platform});
}

// `Office.HostType`
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

// `Office.PlatformType`
@JS()
class PlatformType {
  external factory PlatformType();
}
