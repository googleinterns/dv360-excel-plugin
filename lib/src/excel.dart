@JS()
library excel;

import 'package:fixnum/fixnum.dart';
import 'package:js/js.dart';

import 'office_js.dart';
import 'proto/insertion_order.pb.dart';

/// Service class that provides dart functions to interact with Excel.
class ExcelDart {
  static final _startAddress = 'A1';
  static final _startAddressInt = 'A'.codeUnitAt(0);
  static final _fontName = 'Roboto';
  static final _fontSize = 12;
  static final _horizontalAlignment = 'Center';
  static final _borderStyle = 'Continuous';

  /// Header for the master table.
  ///
  /// If changes have been made to [insertion_order.proto] or
  /// the [_generateTableRow], this table header definition needs to
  /// be changed as well. The length and entries of this table header has to
  /// match with those of the table row generated by [_generateTableRow].
  static final _tableHeader = [
    'Insertion Order ID',
    'Advertiser ID',
    'Campaign ID',
    'Display Name',
    'Entity Status',
    'Update Time',
    'Pacing Period',
    'Pacing Type',
    'Daily Max Micros',
    'Daily Max Impressions',
    'Budget Unit',
    'Automation Type',
    'Budget',
    'Start Date',
    'End Date'
  ];

  /// Waits for Office APIs to be ready and then creates
  /// a new spreadsheet with [sheetName] and populates the spreadsheet with
  /// entries in the [insertionOrderList]
  static void populate(List<InsertionOrder> insertionOrderList) async {
    await Office.onReady(allowInterop((info) async {
      await ExcelJS.run(allowInterop((context) {
        // Adds a new worksheet.
        final sheet = context.workbook.worksheets.add('Query');

        // Turns [insertionOrderList] into table rows.
        final tableBody = insertionOrderList.map(_generateTableRow).toList();

        // Calculates table size and adds a master table.
        final endAddressInt = _startAddressInt + _tableHeader.length - 1;
        final endAddress =
            '${String.fromCharCode(endAddressInt)}${tableBody.length + 1}';
        final tableAddress = 'Query!$_startAddress:$endAddress';
        final table = context.workbook.tables.add(tableAddress, true);

        // Adds and formats table header.
        table.getHeaderRowRange()
          ..values = [_tableHeader]
          ..format.font.name = _fontName
          ..format.font.size = _fontSize
          ..format.font.bold = true
          ..format.horizontalAlignment = _horizontalAlignment
          ..format.borders.getItem('EdgeTop').style = _borderStyle
          ..format.borders.getItem('EdgeBottom').style = _borderStyle;

        // Adds and formats table body.
        table.getDataBodyRange()
          ..formulas = tableBody
          ..format.font.name = _fontName
          ..format.font.size = _fontSize
          ..format.horizontalAlignment = _horizontalAlignment;

        // Auto-fits all used cells.
        sheet.getUsedRange().getEntireColumn().format.autofitColumns();
        sheet.getUsedRange().getEntireRow().format.autofitRows();

        // Sets the sheet as active.
        sheet.activate();
        return context.sync();
      }));
    }));
  }

  static List<String> _generateTableRow(InsertionOrder io) => [
        io.insertionOrderId,
        io.advertiserId,
        io.campaignId,
        io.displayName,
        io.entityStatus.toString(),
        io.updateTime,
        io.pacing.pacingPeriod.toString(),
        io.pacing.pacingType.toString(),
        _calculatePacingDailyMax(io.pacing.dailyMaxMicros),
        io.pacing.dailyMaxImpressions,
        io.budget.budgetUnit.toString(),
        io.budget.automationType.toString(),
        _calculateTotalBudgetAmount(io.budget.budgetSegments),
        _calculateStartDate(io.budget.budgetSegments.first),
        _calculateEndDate(io.budget.budgetSegments.last),
      ];

  static String _calculatePacingDailyMax(String dailyMaxMicros) =>
      dailyMaxMicros.isEmpty
          ? dailyMaxMicros
          : (Int64.parseInt(dailyMaxMicros) * 1e-6).toString();

  /// Todo: calculate budget total for active segments only.
  /// Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/35.
  static String _calculateTotalBudgetAmount(
      List<InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment>
          budgetSegments) {
    final totalBudgetMicros = budgetSegments
        .map((segment) => Int64.parseInt(segment.budgetAmountMicros))
        .reduce((value, element) => value + element);

    /// Todo: conditional formatting for currency.
    /// Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/34.
    return (totalBudgetMicros.toDouble() * 1e-6).toString();
  }

  static String _calculateStartDate(
      InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment
          firstSegment) {
    final startDate = firstSegment.dateRange.startDate;
    return '${startDate.month}/${startDate.day}/${startDate.year}';
  }

  static String _calculateEndDate(
      InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment
          lastSegment) {
    final endDate = lastSegment.dateRange.endDate;
    return '${endDate.month}/${endDate.day}/${endDate.year}';
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

  /// The collection of tables associated with the workbook.
  external TableCollection get tables;

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

  /// Adds a new worksheet to the workbook.
  external Worksheet add(String name);
}

/// Wrapper for Excel.TableCollection class.
///
/// ``` js
///   Excel.TableCollection.add()
/// ```
@JS()
class TableCollection {
  /// Adds a new table to the workbook.
  external Table add(String address, bool hasHeader);
}

/// Wrapper for Excel.Worksheet class.
///
/// ``` js
///   Excel.Worksheet.getRange()
///   Excel.Worksheet.activate()
///   Excel.Worksheet.getUsedRange()
/// ```
@JS()
class Worksheet {
  /// Returns the range object, representing a single rectangular
  /// block of cells, specified by the address.
  external Range getRange(String address);

  /// Activates the worksheet in the Excel UI.
  external void activate();

  /// The smallest range that encompasses any cells that
  /// have a value or formatting assigned to them.
  external Range getUsedRange();
}

/// Wrapper for Excel.Table class.
///
/// ``` js
///   Excel.Table.name
///   Excel.Table.getHeaderRowRange()
///   Excel.Table.getDataBodyRange()
/// ```
@JS()
class Table {
  /// Name of the table.
  external set name(String name);

  /// Gets the range object associated with header row of the table.
  external Range getHeaderRowRange();

  /// Gets the range object associated with the data body of the table.
  external Range getDataBodyRange();
}

/// Wrapper for Excel.Range class.
///
/// ``` js
///   Excel.Range.format
///   Excel.Range.values
///   Excel.Range.getEntireColumn()
///   Excel.Range.getEntireRow()
/// ```
@JS()
class Range {
  /// The RangeFormat object, encapsulating the range's font, fill, borders,
  /// alignment, and other properties.
  external RangeFormat get format;

  /// The raw values of the specified range.
  external set values(dynamic v);

  /// Gets an object that represents the entire column of the range.
  external Range getEntireColumn();

  /// Gets an object that represents the entire row of the range.
  external Range getEntireRow();

  /// Represents the formula in A1-style notation.
  external set formulas(dynamic formulas);
}

/// Wrapper for Excel.RangeFormat class.
///
/// ``` js
///   Excel.RangeFormat.autofitColumns()
///   Excel.RangeFormat.autofitRows()
///   Excel.RangeFormat.font
///   Excel.RangeFormat.borders
/// ```
@JS()
class RangeFormat {
  /// Changes the width of the columns of the current range to
  /// achieve the best fit.
  external void autofitColumns();

  /// Changes the height of the rows of the current range to
  /// achieve the best fit.
  external void autofitRows();

  /// Returns the font object defined on the overall range.
  external RangeFont get font;

  /// Collection of border objects that apply to the overall range.
  external RangeBorderCollection get borders;

  /// Represents the horizontal alignment for the specified object.
  /// Valid values are:  "General", "Left", "Center", "Right", "Fill"
  /// "Justify", "CenterAcrossSelection", "Distributed".
  external set horizontalAlignment(String alignment);
}

/// Wrapper for Excel.RangeFont class.
///
/// ``` js
///   Excel.RangeFont.name
///   Excel.RangeFont.size
///   Excel.RangeFont.color
///   Excel.RangeFont.bold
/// ```
@JS()
class RangeFont {
  /// Font name (e.g., "Calibri").
  external set name(String name);

  /// Font size.
  external set size(int size);

  /// HTML color code representation of the text color
  /// (e.g., #FF0000 represents Red).
  external set color(String color);

  /// Specifies the bold status of font.
  external set bold(bool bold);
}

/// Wrapper for Excel.RangeBorderCollection class.
///
/// ``` js
///   Excel.RangeBorderCollection.getItem()
/// ```
@JS()
class RangeBorderCollection {
  /// Gets a border object using its name.
  /// Valid values are: "EdgeTop", "EdgeBottom", "EdgeLeft", "EdgeRight",
  /// "InsideVertical", "InsideHorizontal", "DiagonalDown", "DiagonalUp".
  external RangeBorder getItem(String value);
}

/// Wrapper for Excel.RangeBorder class.
///
/// ``` js
///   Excel.RangeBorder.style
/// ```
@JS()
class RangeBorder {
  /// Specifies the line style for the border.
  /// Valid values are: "None", "Continuous", "Dash", "DashDot", "DashDotDot",
  /// "Dot", "Double", "SlantDashDot"
  external set style(String style);
}
