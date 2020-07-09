@JS()
library excel;

import 'package:angular/angular.dart';
import 'package:fixnum/fixnum.dart';
import 'package:js/js.dart';

import 'office_js.dart';
import 'proto/insertion_order_query.pb.dart';
import 'util.dart';

/// Service class that provides dart functions to interact with Excel.
@Injectable()
class ExcelDart {
  static const _startAddress = 'A1';
  static final _startAddressInt = 'A'.codeUnitAt(0);
  static const _fontName = 'Roboto';
  static const _fontSize = 12;
  static const _horizontalAlignment = 'Center';
  static const _borderStyle = 'Continuous';
  static const _currencyFormat = '\$#,##0.00';

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
    'Daily Max',
    'Daily Max Impressions',
    'Budget Unit',
    'Automation Type',
    'Budget',
    'Spent',
    'Start Date',
    'End Date'
  ];

  /// Waits for Office APIs to be ready and then creates
  /// a new spreadsheet with [sheetName] and populates the spreadsheet with
  /// entries in the [insertionOrderList].
  void populate(List<InsertionOrder> insertionOrderList) async {
    await Office.onReady(allowInterop((info) async {
      final tableName = 'Performance_Data_Table';

      await ExcelJS.run(allowInterop((context) async {
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
        table.name = tableName;

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

        // Formats the Daily Max and Spent column as currency.
        table.columns.getItem('Daily Max').getRange().numberFormat =
            _currencyFormat;
        table.columns.getItem('Spent').getRange().numberFormat =
            _currencyFormat;

        // Auto-fits all used cells.
        sheet.getUsedRange().getEntireColumn().format.autofitColumns();
        sheet.getUsedRange().getEntireRow().format.autofitRows();

        // Sets the sheet as active.
        sheet.activate();
        return context.sync();
      }));

      // Conditionally format the budget column once the table is set.
      _formatBudgetColumn(tableName);
    }));
  }

  /// Conditionally formats the Budget column based on Budget Unit.
  ///
  /// 'RC[-2]' in the formula follows Excel's Relative Notation and references
  /// the cell that is in the same row but its column number shifted left by 2.
  /// Here the offset between the Budget column and Budget Type Column is -2.
  /// If [_tableHeader] has been changed, the offset here needs to
  /// be changed to match too.
  static void _formatBudgetColumn(String tableName) async {
    await ExcelJS.run(allowInterop((context) async {
      final table = context.workbook.tables.getItem(tableName);
      final budgetRange = table.columns.getItem('Budget').getRange();
      final format = budgetRange.conditionalFormats.add('Custom');

      format.custom.rule.formula = '=IF(INDIRECT("RC[-2]",0) '
          '="${InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY}",'
          'TRUE)';
      format.custom.format.numberFormat = _currencyFormat;

      return context.sync();
    }));
  }

  /// Generates a row from [insertionOrder] by creating fields that matches
  /// those specified in [_tableHeader].
  static List<String> _generateTableRow(InsertionOrder insertionOrder) {
    final activeBudgetSegment = insertionOrder.budget.budgetSegments.first;

    return [
      insertionOrder.insertionOrderId,
      insertionOrder.advertiserId,
      insertionOrder.campaignId,
      insertionOrder.displayName,
      insertionOrder.entityStatus.toString(),
      insertionOrder.updateTime,
      insertionOrder.pacing.pacingPeriod.toString(),
      insertionOrder.pacing.pacingType.toString(),
      _calculatePacingDailyMax(insertionOrder.pacing.dailyMaxMicros),
      insertionOrder.pacing.dailyMaxImpressions,
      insertionOrder.budget.budgetUnit.toString(),
      insertionOrder.budget.automationType.toString(),
      _calculateActiveBudgetAmount(activeBudgetSegment.budgetAmountMicros),
      insertionOrder.spent,
      _calculateDate(activeBudgetSegment.dateRange.startDate),
      _calculateDate(activeBudgetSegment.dateRange.endDate),
    ];
  }

  /// Calculates pacing daily max in standard unit.
  static String _calculatePacingDailyMax(String dailyMaxMicros) =>
      dailyMaxMicros.isEmpty
          ? dailyMaxMicros
          : Util.convertMicrosToStandardUnitString(
              Int64.parseInt(dailyMaxMicros));

  static String _calculateActiveBudgetAmount(String budgetAmountMicros) =>
      Util.convertMicrosToStandardUnitString(
          Int64.parseInt(budgetAmountMicros));

  static String _calculateDate(
          InsertionOrder_Budget_BudgetSegment_DateRange_Date date) =>
      '${date.month}/${date.day}/${date.year}';
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
///   Excel.TableCollection.getItem()
/// ```
@JS()
class TableCollection {
  /// Adds a new table to the workbook.
  external Table add(String address, bool hasHeader);

  /// Gets a table by Name or ID.
  external Table getItem(String key);
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
///   Excel.Table.columns
///   Excel.Table.getHeaderRowRange()
///   Excel.Table.getDataBodyRange()
/// ```
@JS()
class Table {
  /// Name of the table.
  external set name(String name);

  /// Represents a collection of all the columns in the table.
  external TableColumnCollection get columns;

  /// Gets the range object associated with header row of the table.
  external Range getHeaderRowRange();

  /// Gets the range object associated with the data body of the table.
  external Range getDataBodyRange();
}

/// Wrapper for Excel.TableColumnCollection class.
///
/// ``` js
///   Excel.TableColumnCollection.getItem
/// ```
@JS()
class TableColumnCollection {
  /// Gets a column object by Name or ID
  external TableColumn getItem(String key);
}

/// Wrapper for Excel.TableColumnCollection class.
///
/// ``` js
///   Excel.TableColumnCollection.getRange()
/// ```
@JS()
class TableColumn {
  /// Gets the range object associated with the entire column.
  external Range getRange();
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

  /// Represents a collection of all the conditional formats that
  /// are overlap the range.
  external ConditionalFormatCollection get conditionalFormats;

  /// The raw values of the specified range.
  external set values(dynamic v);

  /// Gets an object that represents the entire column of the range.
  external Range getEntireColumn();

  /// Gets an object that represents the entire row of the range.
  external Range getEntireRow();

  /// Represents the formula in A1-style notation.
  external set formulas(dynamic formulas);

  /// Represents Excel's number format code for the given range.
  external set numberFormat(String format);
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

/// Wrapper for Excel.ConditionalFormatCollection class.
///
/// ``` js
///   Excel.ConditionalFormatCollection.add()
/// ```
@JS()
class ConditionalFormatCollection {
  /// Adds a new conditional format to the collection.
  /// Valid values are: "Custom", "DataBar", "ColorScale", "IconSet",
  /// "TopBottom", "PresetCriteria", "ContainsText", "CellValue".
  external ConditionalFormat add(String format);
}

/// Wrapper for Excel.ConditionalFormat class.
///
/// ``` js
///   Excel.ConditionalFormat.custom
/// ```
@JS()
class ConditionalFormat {
  /// The custom conditional format properties if the current
  /// conditional format is a custom type.
  external CustomConditionalFormat get custom;
}

/// Wrapper for Excel.TextConditionalFormat class.
///
/// ``` js
///   Excel.TextConditionalFormat.format
///   Excel.TextConditionalFormat.rule
/// ```
@JS()
class CustomConditionalFormat {
  /// The conditional formats font, fill, borders, and other properties.
  external ConditionalRangeFormat get format;

  /// The Rule object on this conditional format.
  external ConditionalFormatRule get rule;
}

/// Wrapper for Excel.ConditionalRangeFormat class.
///
/// ``` js
///   Excel.ConditionalRangeFormat.numberFormat
/// ```
@JS()
class ConditionalRangeFormat {
  /// Represents Excel's number format code for the given range.
  external set numberFormat(String format);
}

/// Wrapper for Excel.ConditionalFormatRule class.
///
/// ``` js
///   Excel.ConditionalFormatRule.formula
/// ```
@JS()
class ConditionalFormatRule {
  /// Set the conditional format rule on in R1C1-style notation.
  external set formula(String formula);
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
