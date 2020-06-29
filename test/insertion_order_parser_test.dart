import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'package:dv360_excel_plugin/src/insertion_order_parser.dart';
import 'package:dv360_excel_plugin/src/proto/insertion_order.pb.dart';

void main() {
  String input;
  const emptyEntry = '';

  InsertionOrder insertionOrderTemplate;
  InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange
      oneDateRange;
  InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date
      oneStartDate;
  InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date
      oneEndDate;

  setUp(() {
    insertionOrderTemplate = InsertionOrder()
      ..advertiserId = emptyEntry
      ..campaignId = emptyEntry
      ..insertionOrderId = emptyEntry
      ..displayName = emptyEntry
      ..updateTime = emptyEntry
      ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED
      ..pacing = InsertionOrder_Pacing()
      ..budget = InsertionOrder_InsertionOrderBudget();

    oneStartDate =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date()
          ..year = 2019
          ..month = 1
          ..day = 1;

    oneEndDate =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date()
          ..year = 2019
          ..month = 12
          ..day = 31;

    oneDateRange =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange()
          ..startDate = oneStartDate
          ..endDate = oneEndDate;
  });

  tearDown(disposeAnyRunningTest);

  group('parse insertionOrder from empty json:', () {
    setUp(() => input = '{}');

    test('function should return normally', () {
      expect(() => InsertionOrderParser.parse(input), returnsNormally);
    });

    test('result is an empty insertionOrder instance', () {
      final actual = InsertionOrderParser.parse(input);

      final expected = InsertionOrder();
      expect(actual, expected);
    });
  });

  group('parse insertionOrder from json that contains only advertiserId:', () {
    setUp(() => input = '{"advertiserId":"111111"}');

    test('function should return normally', () {
      expect(() => InsertionOrderParser.parse(input), returnsNormally);
    });

    test('result is an insertionOrder with only advertiserId', () {
      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate..advertiserId = '111111';
      expect(actual, expected);
    });
  });

  group('parse insertionOrder from json that contains everything:', () {
    setUp(() {
      final advertiserId = '"advertiserId":"11111"';
      final campaignId = '"campaignId":"2222222"';
      final insertionOrderId = '"insertionOrderId":"3333333"';
      final displayName = '"displayName":"display name"';
      final entityStatus = '"entityStatus":"ENTITY_STATUS_ACTIVE"';
      final updateTime = '"updateTime":"2020-06-23T17:14:58.685Z"';
      final pacing = '"pacing":{"pacingPeriod":"PACING_PERIOD_FLIGHT",'
          '"pacingType":"PACING_TYPE_AHEAD"}';

      final budgetSegment = '"budgetSegments":['
          '{"budgetAmountMicros":"4000000","description":"year-2019",'
          '"dateRange":{"startDate":{"year":2019,"month":1,"day":1},'
          '"endDate":{"year":2019,"month":12,"day":31}}},'
          '{"budgetAmountMicros":"2000000",'
          '"dateRange":{"startDate":{"year":2019,"month":1,"day":1},'
          '"endDate":{"year":2019,"month":12,"day":31}}}]';

      final budget = '"budget":{"budgetUnit":"BUDGET_UNIT_CURRENCY",'
          '"automationType":"INSERTION_ORDER_AUTOMATION_TYPE_NONE",'
          '$budgetSegment}';

      input = '{$advertiserId, $campaignId, $insertionOrderId, $displayName,'
          '$entityStatus, $updateTime, $pacing, $budget}';
    });

    test('function should return normally', () {
      expect(() => InsertionOrderParser.parse(input), returnsNormally);
    });

    test('result is an insertionOrder with all required fields', () {
      final actual = InsertionOrderParser.parse(input);

      final pacing = InsertionOrder_Pacing()
        ..pacingPeriod = InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
        ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
        ..dailyMaxImpressions = emptyEntry;
      final firstSegment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '4000000'
            ..description = 'year-2019'
            ..campaignBudgetId = emptyEntry
            ..dateRange = oneDateRange;
      final secondSegment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '2000000'
            ..description = emptyEntry
            ..campaignBudgetId = emptyEntry
            ..dateRange = oneDateRange;
      final budget = InsertionOrder_InsertionOrderBudget()
        ..budgetUnit =
            InsertionOrder_InsertionOrderBudget_BudgetUnit.BUDGET_UNIT_CURRENCY
        ..automationType =
            InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
                .INSERTION_ORDER_AUTOMATION_TYPE_NONE
        ..budgetSegments.addAll([firstSegment, secondSegment]);
      final expected = InsertionOrder()
        ..advertiserId = '11111'
        ..campaignId = '2222222'
        ..insertionOrderId = '3333333'
        ..displayName = 'display name'
        ..updateTime = '2020-06-23T17:14:58.685Z'
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_ACTIVE
        ..pacing = pacing
        ..budget = budget;
      expect(actual, expected);
    });
  });

  group('parse EntityStatus from json that contains:', () {
    String generateInput(int index) {
      final values = [
        'ENTITY_STATUS_UNSPECIFIED',
        'ENTITY_STATUS_ACTIVE',
        'ENTITY_STATUS_ARCHIVED',
        'ENTITY_STATUS_DRAFT',
        'ENTITY_STATUS_PAUSED',
        'ENTITY_STATUS_SCHEDULED_FOR_DELETION'
      ];

      return '{"entityStatus":"${values[index]}"\}';
    }

    test('ENTITY_STATUS_UNSPECIFIED', () {
      input = generateInput(0);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED;
      expect(actual, expected);
    });

    test('ENTITY_STATUS_ACTIVE', () {
      input = generateInput(1);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_ACTIVE;
      expect(actual, expected);
    });

    test('ENTITY_STATUS_ARCHIVED', () {
      input = generateInput(2);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_ARCHIVED;
      expect(actual, expected);
    });

    test('ENTITY_STATUS_DRAFT', () {
      input = generateInput(3);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_DRAFT;
      expect(actual, expected);
    });

    test('ENTITY_STATUS_PAUSED', () {
      input = generateInput(4);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus = InsertionOrder_EntityStatus.ENTITY_STATUS_PAUSED;
      expect(actual, expected);
    });

    test('ENTITY_STATUS_SCHEDULED_FOR_DELETION', () {
      input = generateInput(5);

      final actual = InsertionOrderParser.parse(input);

      final expected = insertionOrderTemplate
        ..entityStatus =
            InsertionOrder_EntityStatus.ENTITY_STATUS_SCHEDULED_FOR_DELETION;
      expect(actual, expected);
    });
  });

  group('parse Pacing from json that contains:', () {
    test('nothing', () {
      input = '{"pacing":{}}';

      final actual = InsertionOrderParser.parse(input);

      expect(actual, insertionOrderTemplate);
    });

    test('pacingPeriod and pacingType', () {
      input = '{"pacing":{"pacingPeriod":"PACING_PERIOD_FLIGHT",'
          '"pacingType":"PACING_TYPE_AHEAD"}}';

      final actual = InsertionOrderParser.parse(input);

      final pacing = InsertionOrder_Pacing()
        ..pacingPeriod = InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
        ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
        ..dailyMaxImpressions = emptyEntry;
      final expected = insertionOrderTemplate..pacing = pacing;
      expect(actual, expected);
    });

    test('pacingPeriod, pacingType and dailyMaxMicros', () {
      input = '{"pacing":{"pacingPeriod":"PACING_PERIOD_FLIGHT",'
          '"pacingType":"PACING_TYPE_AHEAD",'
          '"dailyMaxMicros": "1500000"}}';

      final actual = InsertionOrderParser.parse(input);

      final pacing = InsertionOrder_Pacing()
        ..pacingPeriod = InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT
        ..pacingType = InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD
        ..dailyMaxMicros = '1500000'
        ..dailyMaxImpressions = emptyEntry;
      final expected = insertionOrderTemplate..pacing = pacing;
      expect(actual, expected);
    });
  });

  group('parse InsertionOrderBudget from json that contains:', () {
    test('nothing', () {
      input = '{"budget":{}}';

      final actual = InsertionOrderParser.parse(input);

      expect(actual, insertionOrderTemplate);
    });

    test('budgetUnit', () {
      input = '{"budget":{"budgetUnit":"BUDGET_UNIT_CURRENCY"}}';

      final actual = InsertionOrderParser.parse(input);

      final budget = InsertionOrder_InsertionOrderBudget()
        ..budgetUnit =
            InsertionOrder_InsertionOrderBudget_BudgetUnit.BUDGET_UNIT_CURRENCY
        ..automationType =
            InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
                .INSERTION_ORDER_AUTOMATION_TYPE_NONE;
      final expected = insertionOrderTemplate..budget = budget;
      expect(actual, expected);
    });

    test('budgetUnit and automationType', () {
      input = '{"budget":{"budgetUnit":"BUDGET_UNIT_CURRENCY",'
          '"automationType":"INSERTION_ORDER_AUTOMATION_TYPE_BUDGET"}}';

      final actual = InsertionOrderParser.parse(input);

      final budget = InsertionOrder_InsertionOrderBudget()
        ..budgetUnit =
            InsertionOrder_InsertionOrderBudget_BudgetUnit.BUDGET_UNIT_CURRENCY
        ..automationType =
            InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
                .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET;
      final expected = insertionOrderTemplate..budget = budget;
      expect(actual, expected);
    });

    test('one budgetSegment', () {
      final budgetSegment = '"budgetSegments":['
          '{"budgetAmountMicros":"5000000",'
          '"dateRange":{"startDate":{"year":2019,"month":1,"day":1},'
          '"endDate":{"year":2019,"month":12,"day":31}}}]';
      input = '{"budget":{$budgetSegment}}';

      final actual = InsertionOrderParser.parse(input);

      final segment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '5000000'
            ..description = emptyEntry
            ..campaignBudgetId = emptyEntry
            ..dateRange = oneDateRange;
      final budget = InsertionOrder_InsertionOrderBudget()
        ..budgetUnit = InsertionOrder_InsertionOrderBudget_BudgetUnit
            .BUDGET_UNIT_UNSPECIFIED
        ..automationType =
            InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
                .INSERTION_ORDER_AUTOMATION_TYPE_NONE
        ..budgetSegments.add(segment);
      final expected = insertionOrderTemplate..budget = budget;
      expect(actual, expected);
    });

    test('multiple budgetSegments', () {
      final budgetSegment = '"budgetSegments":['
          '{"budgetAmountMicros":"5000000",'
          '"dateRange":{"startDate":{"year":2019,"month":1,"day":1},'
          '"endDate":{"year":2019,"month":12,"day":31}}}, '
          '{"budgetAmountMicros":"4000000", "campaignBudgetId": "111111",'
          '"dateRange":{"startDate":{"year":2019,"month":1,"day":1},'
          '"endDate":{"year":2019,"month":12,"day":31}}}, '
          '{"budgetAmountMicros":"3000000", "description":"no date range"}]';
      input = '{"budget":{$budgetSegment}}';

      final actual = InsertionOrderParser.parse(input);

      final firstSegment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '5000000'
            ..description = emptyEntry
            ..campaignBudgetId = emptyEntry
            ..dateRange = oneDateRange;
      final secondSegment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '4000000'
            ..description = emptyEntry
            ..campaignBudgetId = '111111'
            ..dateRange = oneDateRange;
      final thirdSegment =
          InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
            ..budgetAmountMicros = '3000000'
            ..description = 'no date range'
            ..campaignBudgetId = emptyEntry
            ..dateRange =
                InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange();
      final budget = InsertionOrder_InsertionOrderBudget()
        ..budgetUnit = InsertionOrder_InsertionOrderBudget_BudgetUnit
            .BUDGET_UNIT_UNSPECIFIED
        ..automationType =
            InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
                .INSERTION_ORDER_AUTOMATION_TYPE_NONE
        ..budgetSegments.addAll([firstSegment, secondSegment, thirdSegment]);
      final expected = insertionOrderTemplate..budget = budget;
      expect(actual, expected);
    });
  });
}
