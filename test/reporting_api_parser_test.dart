import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/data_model/insertion_order_daily_spend.dart';
import 'package:dv360_excel_plugin/src/reporting_api_parser.dart';
import 'package:quiver/collection.dart';
import 'package:test/test.dart';

void main() {
  group(ReportingQueryParser, () {
    String input;

    tearDown(disposeAnyRunningTest);

    test('parses query id from a json string', () {
      input = '''
        {
           "kind": "doubleclickbidmanager#query",
           "queryId": "1234567",
            "metadata": {
               "title": "jin-test",
               "dataRange": "LAST_14_DAYS",
               "format": "CSV",
               "running": true,
               "sendNotification": false
            },
          "params": {
            "type": "TYPE_GENERAL",
            "groupBys": [
               "FILTER_INSERTION_ORDER",
               "FILTER_DATE"
            ],
            "filters": [
             {
                "type": "FILTER_ADVERTISER",
                "value": "164337"
              }
            ],
            "metrics": [
              "METRIC_REVENUE_USD"
            ]
          },
          "schedule": {
            "frequency": "DAILY"
          }
        }
        ''';

      final actual = ReportingQueryParser.parseQueryIdFromJsonString(input);

      final expected = '1234567';
      expect(actual, expected);
    });

    test('parses download path from a json string', () {
      input = '''
        {
           "kind": "doubleclickbidmanager#query",
           "queryId": "1234567",
            "metadata": {
               "title": "jin-test",
               "dataRange": "LAST_14_DAYS",
               "format": "CSV",
               "running": true,
               "googleCloudStoragePathForLatestReport": "I-am-a-download-link",
               "latestReportRunTimeMs": "1357924",
               "sendNotification": false
            },
          "params": {
            "type": "TYPE_GENERAL",
            "groupBys": [
               "FILTER_INSERTION_ORDER",
               "FILTER_DATE"
            ],
            "filters": [
             {
                "type": "FILTER_ADVERTISER",
                "value": "164337"
              }
            ],
            "metrics": [
              "METRIC_REVENUE_USD"
            ]
          },
          "schedule": {
            "frequency": "DAILY"
          }
        }
        ''';

      final expected =
          ReportingQueryParser.parseDownloadPathFromJsonString(input);

      final actual = 'I-am-a-download-link';
      expect(actual, expected);
    });

    group('parses revenue from:', () {
      Multimap<String, InsertionOrderDailySpend> expected;

      String generateInput(String reportBody) {
        return '''
        {
          "gapiRequest":{
            "data":
            {
              "body":"$reportBody",
              "headers":
              {
                "cache-control":"",
                "content-disposition":"",
                "content-length":"",
                "content-type":"text/csv"
              },
              "status":200
            }
          }
        }
        ''';
      }

      setUp(() => expected = Multimap<String, InsertionOrderDailySpend>());

      test('a report json string that contains no revenue values', () {
        input = generateInput('Insertion Order ID, Revenue');

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        expect(actual, MultimapMatcher(expected));
      });

      test('a report json string that contains a single row of revenue value',
          () {
        final reportBody = 'Insertion Order ID, Date, Revenue, Impression\\n'
            '123456,2020/01/01,88.88,1000\\n';
        input = generateInput(reportBody);

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        final expectedSpending = (InsertionOrderDailySpendBuilder()
              ..date = DateTime(2020, 1, 1)
              ..revenue = '88.88'
              ..impression = '1000')
            .build();
        expected.add('123456', expectedSpending);
        expect(actual, MultimapMatcher(expected));
      });

      test('a report json string that contains multiple rows of revenue values',
          () {
        final reportHeader = 'Insertion Order ID, Date, Revenue, Impression\\n';
        final reportBody = '''
        111111, 2020/01/01, 100.00, 1000\\n
        111111, 2020/02/01, 100.00, 1000\\n
        111111, 2020/03/01, 100.00, 1000\\n
        222222, 2020/02/01, 200.00, 2000\\n
        222222, 2020/02/02, 200.00, 2000\\n
        333333, 2020/03/01, 300.00, 3000\\n
        ''';
        input = generateInput(
            '$reportHeader${reportBody.replaceAll(RegExp(r'\s+'), '')}');

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        expected.add(
            '111111',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 1, 1)
                  ..revenue = '100.00'
                  ..impression = '1000')
                .build());
        expected.add(
            '111111',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 2, 1)
                  ..revenue = '100.00'
                  ..impression = '1000')
                .build());
        expected.add(
            '111111',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 3, 1)
                  ..revenue = '100.00'
                  ..impression = '1000')
                .build());
        expected.add(
            '222222',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 2, 1)
                  ..revenue = '200.00'
                  ..impression = '2000')
                .build());
        expected.add(
            '222222',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 2, 2)
                  ..revenue = '200.00'
                  ..impression = '2000')
                .build());
        expected.add(
            '333333',
            (InsertionOrderDailySpendBuilder()
                  ..date = DateTime(2020, 3, 1)
                  ..revenue = '300.00'
                  ..impression = '3000')
                .build());

        expect(actual, MultimapMatcher(expected));
      });
    });
  });
}

class MultimapMatcher extends Matcher {
  final Multimap _expected;

  MultimapMatcher(this._expected);

  // Copies the MapEqual function.
  // Replaces`bValue == a[k]` in the original function with
  // `listsEqual(bValue, a[k]`
  bool multiMapEqual(Multimap a, Multimap b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final k in a.keys) {
      var bValue = b[k];
      if (bValue == null && !b.containsKey(k)) return false;
      if (!listsEqual(bValue, a[k])) return false;
    }

    return true;
  }

  @override
  Description describe(Description description) {
    description.add('$_expected');
    return description;
  }

  @override
  bool matches(item, Map matchState) {
    return multiMapEqual(item, _expected);
  }
}
