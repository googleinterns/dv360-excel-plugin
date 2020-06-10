@JS('Excel')
library excel;

import 'package:js/js.dart';

/// Wrapper functions for Office Excel APIs
/// Type definitions can be found at:
/// documentation: https://docs.microsoft.com/en-us/javascript/api/excel?view=excel-js-preview

/// ``` javascript function
/// Excel.run()
/// ```
@JS()
external Future<dynamic> run(Future<dynamic> Function(RequestContext) callback);

/// ``` javascript properties and functions
///   Excel.RequestContext.workbook
///   Excel.RequestContext.sync()
/// ```
@JS()
class RequestContext {
  external WorkBook get workbook;
  external Future<dynamic> sync();
}

/// ``` javascript properties and functions
///   Excel.WorkBook.name
///   Excel.WorkBook.worksheets
///   Excel.WorkBook.getSelectedRange()
/// ```
@JS()
class WorkBook {
  external String get name;
  external WorksheetCollection get worksheets;
  external Range getSelectedRange();
}

/// ``` javascript function
///   Excel.WorksheetCollection.getActiveWorksheet()
/// ```
@JS()
class WorksheetCollection {
  external Worksheet getActiveWorksheet();
}

/// ``` javascript function
///   Excel.Worksheet.getRange()
@JS()
class Worksheet {
  external Range getRange(String v);
}

/// ``` javascript properties and functions
///   Excel.Range.format
///   Excel.Range.values
///   Excel.Range.load()
@JS()
class Range {
  external RangeFormat get format;
  external set values(List<List<dynamic>> v);
  external Range load(String v);
}

/// ``` javascript function
///   Excel.RangeFormat.autofitColumns()
@JS()
class RangeFormat {
  external void autofitColumns();
}
