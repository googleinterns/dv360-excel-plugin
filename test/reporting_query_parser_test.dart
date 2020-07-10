import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/reporting_query_parser.dart';
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
        input =
            generateInput('Insertion Order ID, Revenue\\n123456,88.88\\n\\n');

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        final expected = {'123456': '88.88'};
        expect(actual, expected);
      });

      test('a report json string that contains multiple rows of revenue values',
          () {
        final reportBody = 'Insertion Order ID, Revenue\\n'
            '111111,88.88\\n222222,999.999\\n333333,0.00\\n\\n';
        input = generateInput(reportBody);

        final actual = ReportingQueryParser.parseRevenueFromJsonString(input);

        final expected = {
          '111111': '88.88',
          '222222': '999.999',
          '333333': '0.00'
        };
        expect(actual, expected);
      });
    });
  });
}
