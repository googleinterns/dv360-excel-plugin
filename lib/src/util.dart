import 'package:fixnum/fixnum.dart';

class Util {
  /// Convert micros to standard unit.
  static double convertMicros(Int64 micros) => micros.toDouble() * 1e-6;
}
