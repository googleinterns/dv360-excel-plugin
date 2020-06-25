@JS()
library excel;

import 'package:js/js.dart';

import 'office_js.dart';

/// Service class that provides dart functions to interact with Excel.
class ExcelDart {
  ExcelDart._private();

  static final ExcelDart _singleton = ExcelDart._private();

  factory ExcelDart() {
    return _singleton;
  }

  /// Waits for Office APIs to be ready and then executes function [_populate].
  void exec() async {
    await Office.onReady(allowInterop((info) async {
      await ExcelJS.run(allowInterop(_populate));
    }));
  }

  Future<void> _populate(RequestContext context) async {
    final sheet = context.workbook.worksheets.getActiveWorksheet();
    final range = sheet.getRange('A1');
    final values = <List<String>>[
      ['test test']
    ];
    range.values = values;
    range.format.autofitColumns();
    return context.sync();
  }
}

/// Below are wrapper functions for Office Excel APIs.
/// The Type definitions can be found at
/// https://docs.microsoft.com/en-us/javascript/api/excel?view=excel-js-preview.

/// Top level JS class Excel.
///
/// ``` js
///   Excel.run()
/// ```
@JS('Excel')
class ExcelJS {
  /// Executes a batch script that performs actions
  /// on the Excel object model using a new RequestContext.
  external static Future<dynamic> run(
      Future<dynamic> Function(RequestContext) callback);
}

/// Wrapper for Excel.RequestContext class.
///
/// ``` js
///   Excel.RequestContext.workbook
///   Excel.RequestContext.sync()
/// ```
@JS()
class RequestContext {
  /// The current workbook.
  external WorkBook get workbook;

  /// Synchronizes the state between
  /// JavaScript proxy objects and the Office document.
  external Future<void> sync();
}

/// Wrapper for Excel.WorkBook class.
///
/// ``` js
///   Excel.WorkBook.name
///   Excel.WorkBook.worksheets
///   Excel.WorkBook.getSelectedRange()
/// ```
@JS()
class WorkBook {
  /// The name of the workbook.
  external String get name;

  /// The collection of worksheets in the workbook.
  external WorksheetCollection get worksheets;

  /// Returns the currently selected one or more ranges from the workbook.
  external Range getSelectedRange();
}

/// Wrapper for Excel.WorksheetCollection class.
///
/// ``` js
///   Excel.WorksheetCollection.getActiveWorksheet()
/// ```
@JS()
class WorksheetCollection {
  /// Returns the currently active worksheet in the workbook.
  external Worksheet getActiveWorksheet();
}

/// Wrapper for Excel.Worksheet class.
///
/// ``` js
///   Excel.Worksheet.getRange()
/// ```
@JS()
class Worksheet {
  /// Returns the range object, representing a single rectangular
  /// block of cells, specified by the address.
  external Range getRange(String address);
}

/// Wrapper for Excel.Range class.
///
/// ``` js
///   Excel.Range.format
///   Excel.Range.values
///   Excel.Range.load()
/// ```
@JS()
class Range {
  /// The RangeFormat object, encapsulating the range's font, fill, borders,
  /// alignment, and other properties.
  external RangeFormat get format;

  /// The raw values of the specified range.
  external set values(List<List<dynamic>> v);

  /// Loads the specified properties of the object.
  external Range load(String v);
}

/// Wrapper for Excel.RangeFormat class.
///
/// ``` js
///   Excel.RangeFormat.autofitColumns()
/// ```
@JS()
class RangeFormat {
  /// Changes the width of the columns of the current range to
  /// achieve the best fit.
  external void autofitColumns();
}
