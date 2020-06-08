@JS('Excel')
library excel;

import 'package:js/js.dart';

/// Type definitions for Office Excel APIs
/// documentation: https://docs.microsoft.com/en-us/javascript/api/excel?view=excel-js-preview

// Invokes `Excel.run()`
@JS()
external Future<dynamic> run(Future<dynamic> Function(RequestContext) callback);

// `Excel.RequestContext`
@JS()
class RequestContext {
  external WorkBook get workbook;
  external Future<dynamic> sync();
}

// `Excel.WorkBook`
@JS()
class WorkBook {
  external Range getSelectedRange();
  external String get name;
  external WorksheetCollection get worksheets;
}

// `Excel.WorksheetCollection`
@JS()
class WorksheetCollection {
  external Worksheet getActiveWorksheet();
}

// `Excel.Worksheet`
@JS()
class Worksheet {
  external Range getRange(String v);
}

// `Excel.Range`
@JS()
class Range {
  external Range load(String v);
  external RangeFormat get format;
  external set values(List<List<dynamic>> v);
}

// `Excel.RangeFormat`
@JS()
class RangeFormat {
  external void autofitColumns();
}
