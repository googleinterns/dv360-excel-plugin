import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/util.dart';
import 'package:fixnum/fixnum.dart';
import 'package:test/test.dart';

void main() {
  group(Util, () {
    Int64 input;
    String actual;
    String expected;

    tearDown(disposeAnyRunningTest);

    group('parse micros that can be divided by 1e6 with no remainder:', () {
      test('input is 1,000,000', () {
        input = Int64(1000000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '1';
        expect(actual, expected);
      });

      test('input is 25,000,000', () {
        input = Int64(25000000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '25';
        expect(actual, expected);
      });

      test('input is 9,000,000,000,000,000,000', () {
        input = Int64(9000000000000000000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '9000000000000';
        expect(actual, expected);
      });
    });

    group('parse micros that can be divided by 1e6 with remainder:', () {
      test('input is 0', () {
        input = Int64.ZERO;

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0';
        expect(actual, expected);
      });

      test('input is 1', () {
        input = Int64.ONE;

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.000001';
        expect(actual, expected);
      });

      test('input is 10', () {
        input = Int64(10);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.000010';
        expect(actual, expected);
      });

      test('input is 100', () {
        input = Int64(100);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.000100';
        expect(actual, expected);
      });

      test('input is 1000', () {
        input = Int64(1000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.001000';
        expect(actual, expected);
      });

      test('input is 10000', () {
        input = Int64(10000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.010000';
        expect(actual, expected);
      });

      test('input is 100000', () {
        input = Int64(100000);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.100000';
        expect(actual, expected);
      });

      test('input is 123456', () {
        input = Int64(123456);

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '0.123456';
        expect(actual, expected);
      });

      test('input is Int64.MAX_VALUE 9,223,372,036,854,775,807', () {
        input = Int64.MAX_VALUE;

        actual = Util.convertMicrosToStandardUnitString(input);

        expected = '9223372036854.775807';
        expect(actual, expected);
      });
    });
  });
}
