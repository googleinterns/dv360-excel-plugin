import 'package:decimal/decimal.dart';
import 'package:fixnum/fixnum.dart';
import 'package:intl/intl.dart';

import 'proto/insertion_order_query.pb.dart';

enum QueryType { byAdvertiser, byMediaPlan, byInsertionOrder }

extension QueryTypeExtension on QueryType {
  static const names = {
    QueryType.byAdvertiser: 'Insertion Orders Under Advertiser',
    QueryType.byMediaPlan: 'Insertion Orders Under Campaign',
    QueryType.byInsertionOrder: 'Single Insertion Order'
  };

  static const shortNames = {
    QueryType.byAdvertiser: 'by-advertiser',
    QueryType.byMediaPlan: 'by-media-plan',
    QueryType.byInsertionOrder: 'by-io'
  };

  String get name => names[this];
  String get shortName => shortNames[this];
}

class QueryBuilderException implements Exception {
  final String _message;
  QueryBuilderException(this._message);

  @override
  String toString() {
    return _message;
  }
}

class Util {
  /// Convert micros to string in standard unit.
  static String convertMicrosToStandardUnitString(Int64 micros) {
    final remainder = micros % 1e6;
    final truncatedDivision = micros ~/ 1e6;

    final length = micros.toString().length;
    final paddingZeros = length >= 6 ? '' : ''.padRight(6 - length, '0');

    return remainder == 0
        ? truncatedDivision.toString()
        : '$truncatedDivision.$paddingZeros$remainder';
  }

  /// Convert a proto [Date] instance to Dart DateTime.
  static DateTime convertProtoDateToDateTime(
          InsertionOrder_Budget_BudgetSegment_DateRange_Date date) =>
      DateTime(date.year, date.month, date.day);

  /// Convert a string date(yyyy/mm/dd) to Dart DateTime.
  static DateTime convertStringDateToDateTime(String date) {
    return DateFormat('yyyy/MM/dd').parse(date);
  }

  /// Return `true` if [target] is before [start] and after [end],
  /// false otherwise.
  /// TODO: make sure all dates are at the same time zone.
  /// Issue: https://github.com/googleinterns/dv360-excel-plugin/issues/51
  static bool isBetweenDates(DateTime target, DateTime start, DateTime end) =>
      (target.isAfter(start) || target.isAtSameMomentAs(start)) &&
      (target.isBefore(end) || target.isAtSameMomentAs(end));

  /// Add two string values together.
  static String addStringRevenue(String revenueA, String revenueB) =>
      (Decimal.parse(revenueA) + Decimal.parse(revenueB)).toString();
}
