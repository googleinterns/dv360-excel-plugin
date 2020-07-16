import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/reporting_api_parser.dart';
import 'package:js/js_util.dart';
import 'package:test/test.dart';

void main() {
  group(ReportingQueryParser, () {
    String input;
    const emptyEntry = '';

    tearDown(disposeAnyRunningTest);

    group('parses query id from:', () {
      test('null', () {
        final actual = ReportingQueryParser.parseQueryIdFromJsonString(null);

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test('an empty json string', () {
        input = '{}';

        final actual = ReportingQueryParser.parseQueryIdFromJsonString(input);

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test('a json string that include field queryId', () {
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
    });

    group('parses download path from:', () {
      test('null', () {
        final actual =
            ReportingQueryParser.parseDownloadPathFromJsonString(null);

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test('an empty json string', () {
        input = '{}';

        final actual =
            ReportingQueryParser.parseDownloadPathFromJsonString(input);

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test(
          'a json string that include field googleCloudStoragePathForLatestReport',
          () {
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
    });

    group('parses revenue from:', () {
      const emptyMap = <String, String>{};

      test('null', () {
        final actual = ReportingQueryParser.parseRevenueFromJsonString(null);

        final expected = emptyMap;
        expect(actual, expected);
      });

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

      test('an empty report json string', () {
        input = '{}';

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        final expected = emptyMap;
        expect(actual, expected);
      });

      test('a report json string that contains no revenue values', () {
        input = generateInput('Insertion Order ID, Revenue');

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        final expected = emptyMap;
        expect(actual, expected);
      });

      test('a report json string that contains a single row of revenue value',
          () {
        final reportBody = 'Insertion Order ID, Date, Revenue, Impression\\n'
            '123456,2020/01/01,88.88,1000\\n';
        input = generateInput(reportBody);

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        expect(actual is Map<String, List<InsertionOrderDailySpend>>, true);

        expect(actual['123456'] is List<InsertionOrderDailySpend>, true);
        expect(actual['123456'].length, 1);
        expect(actual['123456'].first.date, DateTime(2020, 1, 1));
        expect(actual['123456'].first.revenue, '88.88');
        expect(actual['123456'].first.impression, '1000');
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
        final firstSpending = actual['111111'];
        final secondSpending = actual['222222'];
        final thirdSpending = actual['333333'];

        expect(actual is Map<String, List<InsertionOrderDailySpend>>, true);

        expect(firstSpending is List<InsertionOrderDailySpend>, true);
        expect(firstSpending.length, 3);
        expect(firstSpending.first.date, DateTime(2020, 1, 1));
        expect(firstSpending.first.revenue, '100.00');
        expect(firstSpending.first.impression, '1000');
        expect(firstSpending[1].date, DateTime(2020, 2, 1));
        expect(firstSpending[1].revenue, '100.00');
        expect(firstSpending[1].impression, '1000');
        expect(firstSpending.last.date, DateTime(2020, 3, 1));
        expect(firstSpending.last.revenue, '100.00');
        expect(firstSpending.last.impression, '1000');

        expect(secondSpending is List<InsertionOrderDailySpend>, true);
        expect(secondSpending.length, 2);
        expect(secondSpending.first.date, DateTime(2020, 2, 1));
        expect(secondSpending.first.revenue, '200.00');
        expect(secondSpending.first.impression, '2000');
        expect(secondSpending.last.date, DateTime(2020, 2, 2));
        expect(secondSpending.last.revenue, '200.00');
        expect(secondSpending.last.impression, '2000');

        expect(thirdSpending is List<InsertionOrderDailySpend>, true);
        expect(thirdSpending.length, 1);
        expect(thirdSpending.first.date, DateTime(2020, 3, 1));
        expect(thirdSpending.first.revenue, '300.00');
        expect(thirdSpending.first.impression, '3000');
      });
    });
  });
}
