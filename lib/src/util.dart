import 'package:fixnum/fixnum.dart';

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
}
