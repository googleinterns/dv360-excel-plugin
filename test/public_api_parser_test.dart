import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/src/public_api_parser.dart';
import 'package:dv360_excel_plugin/src/proto/insertion_order_query.pb.dart';
import 'package:test/test.dart';

void main() {
  group(PublicApiParser, () {
    String input;
    const emptyEntry = '';

    InsertionOrder insertionOrderTemplate;
    InsertionOrder_Budget_BudgetSegment_DateRange oneDateRange;
    InsertionOrder_Budget_BudgetSegment_DateRange_Date oneStartDate;
    InsertionOrder_Budget_BudgetSegment_DateRange_Date oneEndDate;

    setUp(() {
      insertionOrderTemplate = InsertionOrder()
        ..advertiserId = emptyEntry
        ..campaignId = emptyEntry
        ..insertionOrderId = emptyEntry
        ..displayName = emptyEntry
        ..updateTime = emptyEntry
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED
        ..pacing = InsertionOrder_Pacing()
        ..budget = InsertionOrder_Budget()
        ..spent = '0';

      oneStartDate = InsertionOrder_Budget_BudgetSegment_DateRange_Date()
        ..year = 2020
        ..month = 1
        ..day = 1;

      oneEndDate = InsertionOrder_Budget_BudgetSegment_DateRange_Date()
        ..year = 2020
        ..month = 12
        ..day = 31;

      oneDateRange = InsertionOrder_Budget_BudgetSegment_DateRange()
        ..startDate = oneStartDate
        ..endDate = oneEndDate;
    });

    tearDown(disposeAnyRunningTest);

    group('parses insertion orders from:', () {
      test('empty json string', () {
        final actual = PublicApiParser.parseInsertionOrders('{}');

        final expected = [InsertionOrder()];
        expect(actual, expected);
      });

      test('json that contains only advertiserId', () {
        input = '{"advertiserId":"111111"}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final expected = insertionOrderTemplate..advertiserId = '111111';
        expect(actual, [expected]);
      });

      test('json that contains everything', () {
        final advertiserId = '"advertiserId":"11111"';
        final campaignId = '"campaignId":"2222222"';
        final insertionOrderId = '"insertionOrderId":"3333333"';
        final displayName = '"displayName":"display name"';
        final entityStatus = '"entityStatus":"ENTITY_STATUS_ACTIVE"';
        final updateTime = '"updateTime":"2020-06-23T17:14:58.685Z"';
        final pacing = '''
          "pacing":{
            "pacingPeriod":"PACING_PERIOD_FLIGHT",
            "pacingType":"PACING_TYPE_AHEAD"
          }
          ''';
        final budgetSegment = '''
          "budgetSegments":[
            {"budgetAmountMicros":"4000000",
             "description":"year-2019",
             "dateRange":{
                "startDate":{"year":2019,"month":1,"day":1},
                "endDate":{"year":2019,"month":12,"day":31}
             }
            },
            {"budgetAmountMicros":"2000000",
             "dateRange":{
                "startDate":{"year":2020,"month":1,"day":1},
                "endDate":{"year":2020,"month":12,"day":31}
             }
            }
          ]
          ''';
        final budget = '''
          "budget":{
            "budgetUnit":"BUDGET_UNIT_CURRENCY",
            "automationType":"INSERTION_ORDER_AUTOMATION_TYPE_NONE",
            $budgetSegment
           }
          ''';
        input = '{$advertiserId, $campaignId, $insertionOrderId, $displayName,'
            '$entityStatus, $updateTime, $pacing, $budget}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final expectedPacing = InsertionOrder_Pacing()
          ..pacingPeriod =
              InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
          ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
          ..dailyMaxImpressions = emptyEntry;
        final segment = InsertionOrder_Budget_BudgetSegment()
          ..budgetAmountMicros = '2000000'
          ..description = emptyEntry
          ..campaignBudgetId = emptyEntry
          ..dateRange = oneDateRange;
        final expectedBudget = InsertionOrder_Budget()
          ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE
          ..activeBudgetSegment = segment;
        final expected = InsertionOrder()
          ..advertiserId = '11111'
          ..campaignId = '2222222'
          ..insertionOrderId = '3333333'
          ..displayName = 'display name'
          ..updateTime = '2020-06-23T17:14:58.685Z'
          ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_ACTIVE
          ..pacing = expectedPacing
          ..budget = expectedBudget
          ..spent = '0';
        expect(actual, [expected]);
      });
    });

    group('parses next page token from:', () {
      test('empty json string', () {
        final actual = PublicApiParser.parseNextPageToken('{}');

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test('json that does not contain next page token', () {
        input = '{"some-field": "some-value", "not-token" : "not_token_value"}';
        final actual = PublicApiParser.parseNextPageToken(input);

        final expected = emptyEntry;
        expect(actual, expected);
      });

      test('json that contains next page token', () {
        input = '{"some-field": "some-value", "nextPageToken" : "token_value"}';
        final actual = PublicApiParser.parseNextPageToken(input);

        final expected = 'token_value';
        expect(actual, expected);
      });
    });

    group('parses Pacing from json that contains:', () {
      test('nothing', () {
        input = '{"pacing":{}}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        expect(actual, [insertionOrderTemplate]);
      });

      test('pacingPeriod and pacingType', () {
        input = '''
          {
            "pacing":{
              "pacingPeriod":"PACING_PERIOD_FLIGHT",
              "pacingType":"PACING_TYPE_AHEAD"
            }
          }
          ''';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final pacing = InsertionOrder_Pacing()
          ..pacingPeriod =
              InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
          ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
          ..dailyMaxImpressions = emptyEntry;
        final expected = insertionOrderTemplate..pacing = pacing;
        expect(actual, [expected]);
      });

      test('pacingPeriod, pacingType and dailyMaxMicros', () {
        input = '''
          {
            "pacing":{
              "pacingPeriod":"PACING_PERIOD_FLIGHT",
              "pacingType":"PACING_TYPE_AHEAD",
              "dailyMaxMicros": "1500000"
            }
          }
          ''';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final pacing = InsertionOrder_Pacing()
          ..pacingPeriod =
              InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
          ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
          ..dailyMaxMicros = '1500000'
          ..dailyMaxImpressions = emptyEntry;
        final expected = insertionOrderTemplate..pacing = pacing;
        expect(actual, [expected]);
      });
    });

    group('parses InsertionOrderBudget from json that contains:', () {
      test('nothing', () {
        input = '{"budget":{}}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        expect(actual, [insertionOrderTemplate]);
      });

      test('budgetUnit', () {
        input = '{"budget":{"budgetUnit":"BUDGET_UNIT_CURRENCY"}}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final budget = InsertionOrder_Budget()
          ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE
          ..activeBudgetSegment = InsertionOrder_Budget_BudgetSegment();
        final expected = insertionOrderTemplate..budget = budget;
        expect(actual, [expected]);
      });

      test('budgetUnit and automationType', () {
        input = '''
          {
            "budget":{
              "budgetUnit":"BUDGET_UNIT_CURRENCY",
              "automationType":"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"
              }
          }
          ''';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final budget = InsertionOrder_Budget()
          ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET
          ..activeBudgetSegment = InsertionOrder_Budget_BudgetSegment();
        final expected = insertionOrderTemplate..budget = budget;
        expect(actual, [expected]);
      });

      test('empty budgetSegment', () {
        input = '''
          {
            "budget":{
              "budgetUnit":"BUDGET_UNIT_CURRENCY",
              "automationType":"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET",
              "budgetSegments": [{}]
            }
          }
          ''';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final budget = InsertionOrder_Budget()
          ..budgetUnit = InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_CURRENCY
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET
          ..activeBudgetSegment = InsertionOrder_Budget_BudgetSegment();
        final expected = insertionOrderTemplate..budget = budget;
        expect(actual, [expected]);
      });

      test('one budgetSegment that is active', () {
        final budgetSegment = '''
          "budgetSegments":[
            {
              "budgetAmountMicros":"5000000",
              "dateRange":{
                "startDate":{"year":2020,"month":1,"day":1},
                "endDate":{"year":2020,"month":12,"day":31}
              }
            }
          ]
          ''';
        input = '{"budget":{$budgetSegment}}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final segment = InsertionOrder_Budget_BudgetSegment()
          ..budgetAmountMicros = '5000000'
          ..description = emptyEntry
          ..campaignBudgetId = emptyEntry
          ..dateRange = oneDateRange;
        final budget = InsertionOrder_Budget()
          ..budgetUnit =
              InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_UNSPECIFIED
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE
          ..activeBudgetSegment = segment;
        final expected = insertionOrderTemplate..budget = budget;
        expect(actual, [expected]);
      });

      test('multiple budgetSegments that contains one active', () {
        final budgetSegment = '''
          "budgetSegments":[
            {
              "budgetAmountMicros":"5000000",
              "dateRange":{
                "startDate":{"year":2019,"month":1,"day":1},
                "endDate":{"year":2019,"month":12,"day":31}
              }
            },
            {
              "budgetAmountMicros":"4000000",
              "campaignBudgetId": "111111",
              "dateRange":{
                "startDate":{"year":2020,"month":1,"day":1},
                "endDate":{"year":2020,"month":12,"day":31}
              }
            },
            {
              "budgetAmountMicros":"3000000",
              "description":"no date range"
            }
          ]
          ''';
        input = '{"budget":{$budgetSegment}}';

        final actual = PublicApiParser.parseInsertionOrders(input);

        final segment = InsertionOrder_Budget_BudgetSegment()
          ..budgetAmountMicros = '4000000'
          ..description = emptyEntry
          ..campaignBudgetId = '111111'
          ..dateRange = oneDateRange;
        final budget = InsertionOrder_Budget()
          ..budgetUnit =
              InsertionOrder_Budget_BudgetUnit.BUDGET_UNIT_UNSPECIFIED
          ..automationType = InsertionOrder_Budget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE
          ..activeBudgetSegment = segment;
        final expected = insertionOrderTemplate..budget = budget;
        expect(actual, [expected]);
      });
    });
  });
}
