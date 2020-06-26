import 'dart:math';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'package:dv360_excel_plugin/src/parser.dart';
import 'package:dv360_excel_plugin/src/proto/insertion_order.pb.dart';

void main() {
  const max = 10000;
  const displayName = 'display name';
  const updateTime = 'update time';
  const entityStatus = 'ENTITY_STATUS_ACTIVE';
  const pacingPeriod = 'PACING_PERIOD_DAILY';
  const pacingType = 'PACING_TYPE_AHEAD';
  const budgetUnit = 'BUDGET_UNIT_IMPRESSIONS';
  const automationType = 'INSERTION_ORDER_AUTOMATION_TYPE_BUDGET';
  const description = 'test description';
  const startYear = 2019;
  const startMonth = 1;
  const startDay = 1;
  const endYear = 2020;
  const endMonth = 12;
  const endDay = 30;
  const empty = 0;

  Random random;
  String advertiserId;
  String campaignId;
  String insertionOrderId;
  String maxImpressions;
  String budgetAmountMicros;
  String campaignBudgetId;
  Map<String, dynamic> insertionOrderMap;

  setUp(() {
    random = Random();

    advertiserId = random.nextInt(max).toString();
    campaignId = random.nextInt(max).toString();
    insertionOrderId = random.nextInt(max).toString();
    maxImpressions = random.nextInt(max).toString();
    budgetAmountMicros = random.nextInt(max).toString();
    campaignBudgetId = random.nextInt(max).toString();

    insertionOrderMap = <String, dynamic>{
      'advertiserId': advertiserId,
      'campaignId': campaignId,
      'insertionOrderId': insertionOrderId,
      'displayName': displayName,
      'updateTime': updateTime,
      'entityStatus': entityStatus,
      'pacing': <String, dynamic>{
        'pacingPeriod': pacingPeriod,
        'pacingType': pacingType,
        'dailyMaxImpressions': maxImpressions,
      },
      'budget': <String, dynamic>{
        'budgetUnit': budgetUnit,
        'automationType': automationType,
        'budgetSegments': [
          <String, dynamic>{
            'budgetAmountMicros': budgetAmountMicros,
            'description': description,
            'campaignBudgetId': campaignBudgetId,
            'dateRange': <String, dynamic>{
              'startDate': {
                'year': startYear,
                'month': startMonth,
                'day': startDay
              },
              'endDate': {'year': endYear, 'month': endMonth, 'day': endDay}
            }
          }
        ],
      }
    };
  });

  tearDown(disposeAnyRunningTest);

  group('parsing string map to InsertionOrder', () {
    Map<String, dynamic> map;
    InsertionOrder insertionOrder;

    setUp(() {
      map = Map.from(insertionOrderMap);
    });

    test('a full InsertionOrder', () {
      expect(() => Parser.createInsertionOrder(map), returnsNormally);
      insertionOrder = Parser.createInsertionOrder(map);
      expect(insertionOrder.advertiserId, advertiserId);
      expect(insertionOrder.campaignId, campaignId);
      expect(insertionOrder.insertionOrderId, insertionOrderId);
      expect(insertionOrder.displayName, displayName);
      expect(insertionOrder.updateTime, updateTime);
      expect(insertionOrder.entityStatus,
          InsertionOrder_EntityStatus.ENTITY_STATUS_ACTIVE);

      final pacing = insertionOrder.pacing;
      expect(pacing.pacingPeriod,
          InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_DAILY);
      expect(pacing.pacingType,
          InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD);
      expect(pacing.dailyMaxImpressions, maxImpressions);
      expect(pacing.dailyMaxMicros, isEmpty);

      final budget = insertionOrder.budget;
      expect(
          budget.budgetUnit,
          InsertionOrder_InsertionOrderBudget_BudgetUnit
              .BUDGET_UNIT_IMPRESSIONS);
      expect(
          budget.automationType,
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET);
      expect(budget.budgetSegments.length, 1);

      final budgetSegment = budget.budgetSegments[0];
      expect(budgetSegment.budgetAmountMicros, budgetAmountMicros);
      expect(budgetSegment.description, description);
      expect(budgetSegment.campaignBudgetId, campaignBudgetId);
      expect(budgetSegment.dateRange.startDate.year, startYear);
      expect(budgetSegment.dateRange.startDate.month, startMonth);
      expect(budgetSegment.dateRange.startDate.day, startDay);
      expect(budgetSegment.dateRange.endDate.year, endYear);
      expect(budgetSegment.dateRange.endDate.month, endMonth);
      expect(budgetSegment.dateRange.endDate.day, endDay);
    });
  });

  group('parsing string map to Pacing:', () {
    Map<String, dynamic> map;
    InsertionOrder_Pacing pacing;

    setUp(() {
      map = Map.from(insertionOrderMap['pacing']);
    });

    test('a full Pacing', () {
      expect(() => Parser.createPacing(map), returnsNormally);
      pacing = Parser.createPacing(map);
      expect(pacing.pacingPeriod,
          InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_DAILY);
      expect(pacing.pacingType,
          InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD);
      expect(pacing.dailyMaxImpressions, maxImpressions);
      expect(pacing.dailyMaxMicros, isEmpty);
    });

    test('dailyMaxImpressions can be optional', () {
      map.remove('dailyMaxImpressions');
      expect(() => Parser.createPacing(map), returnsNormally);
    });
  });

  group('parsing string map to Budget', () {
    Map<String, dynamic> map;
    InsertionOrder_InsertionOrderBudget budget;

    setUp(() {
      map = Map.from(insertionOrderMap['budget']);
    });

    test('a full Budget', () {
      expect(() => Parser.createBudget(map), returnsNormally);
      budget = Parser.createBudget(map);
      expect(
          budget.budgetUnit,
          InsertionOrder_InsertionOrderBudget_BudgetUnit
              .BUDGET_UNIT_IMPRESSIONS);
      expect(
          budget.automationType,
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET);
      expect(budget.budgetSegments.length, 1);

      final budgetSegment = budget.budgetSegments[0];
      expect(budgetSegment.budgetAmountMicros, budgetAmountMicros);
      expect(budgetSegment.description, description);
      expect(budgetSegment.campaignBudgetId, campaignBudgetId);
      expect(budgetSegment.dateRange.startDate.year, startYear);
      expect(budgetSegment.dateRange.startDate.month, startMonth);
      expect(budgetSegment.dateRange.startDate.day, startDay);
      expect(budgetSegment.dateRange.endDate.year, endYear);
      expect(budgetSegment.dateRange.endDate.month, endMonth);
      expect(budgetSegment.dateRange.endDate.day, endDay);
    });

    test(
        'automationType can be optional and should default to '
        'INSERTION_ORDER_AUTOMATION_TYPE_NONE', () {
      map.remove('automationType');
      expect(() => Parser.createBudget(map), returnsNormally);
      budget = Parser.createBudget(map);
      expect(
          budget.automationType,
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE);
    });

    test('adding more budgetSegment to the budgetSegments list', () {
      final segment = map['budgetSegments'][0];
      map['budgetSegments'].add(segment);
      expect(() => Parser.createBudget(map), returnsNormally);
      budget = Parser.createBudget(map);
      for (var segment in budget.budgetSegments) {
        expect(segment.budgetAmountMicros, budgetAmountMicros);
        expect(segment.description, description);
        expect(segment.campaignBudgetId, campaignBudgetId);
        expect(segment.dateRange.startDate.year, startYear);
        expect(segment.dateRange.startDate.month, startMonth);
        expect(segment.dateRange.startDate.day, startDay);
        expect(segment.dateRange.endDate.year, endYear);
        expect(segment.dateRange.endDate.month, endMonth);
        expect(segment.dateRange.endDate.day, endDay);
      }
    });
  });

  group('parsing string map to BudgetSegment', () {
    Map<String, dynamic> map;
    InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment
        budgetSegment;

    setUp(() {
      map = Map.from(insertionOrderMap['budget']['budgetSegments'][0]);
    });

    test('a full BudgetSegment', () {
      expect(() => Parser.createBudgetSegment(map), returnsNormally);
      budgetSegment = Parser.createBudgetSegment(map);
      expect(budgetSegment.budgetAmountMicros, budgetAmountMicros);
      expect(budgetSegment.description, description);
      expect(budgetSegment.campaignBudgetId, campaignBudgetId);
      expect(budgetSegment.dateRange.startDate.year, startYear);
      expect(budgetSegment.dateRange.startDate.month, startMonth);
      expect(budgetSegment.dateRange.startDate.day, startDay);
      expect(budgetSegment.dateRange.endDate.year, endYear);
      expect(budgetSegment.dateRange.endDate.month, endMonth);
      expect(budgetSegment.dateRange.endDate.day, endDay);
    });

    test('description can be optional', () {
      map.remove('description');
      expect(() => Parser.createBudgetSegment(map), returnsNormally);
    });

    test('campaignBudgetId can be optional', () {
      map.remove('campaignBudgetId');
      expect(() => Parser.createBudgetSegment(map), returnsNormally);
    });
  });

  group('parsing string map to DateRange:', () {
    Map<String, dynamic> map;
    InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange
        dateRange;

    setUp(() {
      map = Map.from(
          insertionOrderMap['budget']['budgetSegments'][0]['dateRange']);
    });

    test('a full DateRange', () {
      expect(() => Parser.createDateRange(map), returnsNormally);
      dateRange = Parser.createDateRange(map);
      expect(dateRange.startDate.year, startYear);
      expect(dateRange.startDate.month, startMonth);
      expect(dateRange.startDate.day, startDay);
      expect(dateRange.endDate.year, endYear);
      expect(dateRange.endDate.month, endMonth);
      expect(dateRange.endDate.day, endDay);
    });

    test('start date can be optional', () {
      map.remove('startDate');
      expect(() => Parser.createDateRange(map), returnsNormally);
      dateRange = Parser.createDateRange(map);
      expect(dateRange.startDate.year, empty);
      expect(dateRange.startDate.month, empty);
      expect(dateRange.startDate.day, empty);
      expect(dateRange.endDate.year, endYear);
      expect(dateRange.endDate.month, endMonth);
      expect(dateRange.endDate.day, endDay);
    });

    test('end date can be optional', () {
      map.remove('endDate');
      expect(() => Parser.createDateRange(map), returnsNormally);
      dateRange = Parser.createDateRange(map);
      expect(dateRange.startDate.year, startYear);
      expect(dateRange.startDate.month, startMonth);
      expect(dateRange.startDate.day, startDay);
      expect(dateRange.endDate.year, empty);
      expect(dateRange.endDate.month, empty);
      expect(dateRange.endDate.day, empty);
    });
  });

  group('parsing string map to Date:', () {
    Map<String, dynamic> map;
    InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date
        date;

    setUp(() {
      map = Map.from(insertionOrderMap['budget']['budgetSegments'][0]
          ['dateRange']['startDate']);
    });

    test('a full date', () {
      expect(() => Parser.createDate(map), returnsNormally);
      date = Parser.createDate(map);
      expect(date.year, startYear);
      expect(date.month, startMonth);
      expect(date.day, startDay);
    });

    test('year can be optional', () {
      map.remove('year');
      expect(() => Parser.createDate(map), returnsNormally);
      date = Parser.createDate(map);
      expect(date.year, empty);
      expect(date.month, startMonth);
      expect(date.day, startDay);
    });

    test('day can be optional', () {
      map.remove('day');
      expect(() => Parser.createDate(map), returnsNormally);
      date = Parser.createDate(map);
      expect(date.year, startYear);
      expect(date.month, startMonth);
      expect(date.day, empty);
    });

    test('year and month can be optional', () {
      map.remove('year');
      map.remove('month');
      expect(() => Parser.createDate(map), returnsNormally);
      date = Parser.createDate(map);
      expect(date.year, empty);
      expect(date.month, empty);
      expect(date.day, startDay);
    });
  });

  group('parsing string to InsertionOrder_EntityStatus enum:', () {
    String status;

    test('ENTITY_STATUS_UNSPECIFIED', () {
      status = 'ENTITY_STATUS_UNSPECIFIED';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED);
    });

    test('ENTITY_STATUS_ACTIVE', () {
      status = 'ENTITY_STATUS_ACTIVE';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_ACTIVE);
    });

    test('ENTITY_STATUS_ARCHIVED', () {
      status = 'ENTITY_STATUS_ARCHIVED';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_ARCHIVED);
    });

    test('ENTITY_STATUS_DRAFT', () {
      status = 'ENTITY_STATUS_DRAFT';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_DRAFT);
    });

    test('ENTITY_STATUS_PAUSED', () {
      status = 'ENTITY_STATUS_PAUSED';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_PAUSED);
    });

    test('ENTITY_STATUS_SCHEDULED_FOR_DELETION', () {
      status = 'ENTITY_STATUS_SCHEDULED_FOR_DELETION';
      expect(Parser.createEntityStatus(status),
          InsertionOrder_EntityStatus.ENTITY_STATUS_SCHEDULED_FOR_DELETION);
    });

    test('NOT_SUPPORT', () {
      status = 'NOT_SUPPORT';
      expect(() => Parser.createEntityStatus(status), throwsFormatException);
    });

    test('null entry', () {
      expect(() => Parser.createEntityStatus(null), throwsFormatException);
    });
  });

  group('parsing string to InsertionOrder_Pacing_PacingPeriod enum:', () {
    String period;

    test('PACING_PERIOD_UNSPECIFIED', () {
      period = 'PACING_PERIOD_UNSPECIFIED';
      expect(Parser.createPacingPeriod(period),
          InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_UNSPECIFIED);
    });

    test('PACING_PERIOD_DAILY', () {
      period = 'PACING_PERIOD_DAILY';
      expect(Parser.createPacingPeriod(period),
          InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_DAILY);
    });

    test('PACING_PERIOD_FLIGHT', () {
      period = 'PACING_PERIOD_FLIGHT';
      expect(Parser.createPacingPeriod(period),
          InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_FLIGHT);
    });

    test('NOT_SUPPORTED', () {
      period = 'NOT_SUPPORTED';
      expect(() => Parser.createPacingPeriod(period), throwsFormatException);
    });

    test('null entry', () {
      expect(() => Parser.createPacingPeriod(null), throwsFormatException);
    });
  });

  group('parsing string to InsertionOrder_Pacing_PacingType enum:', () {
    String type;

    test('PACING_TYPE_UNSPECIFIED', () {
      type = 'PACING_TYPE_UNSPECIFIED';
      expect(Parser.createPacingType(type),
          InsertionOrder_Pacing_PacingType.PACING_TYPE_UNSPECIFIED);
    });

    test('PACING_TYPE_AHEAD', () {
      type = 'PACING_TYPE_AHEAD';
      expect(Parser.createPacingType(type),
          InsertionOrder_Pacing_PacingType.PACING_TYPE_AHEAD);
    });

    test('PACING_TYPE_ASAP', () {
      type = 'PACING_TYPE_ASAP';
      expect(Parser.createPacingType(type),
          InsertionOrder_Pacing_PacingType.PACING_TYPE_ASAP);
    });

    test('PACING_TYPE_EVEN', () {
      type = 'PACING_TYPE_EVEN';
      expect(Parser.createPacingType(type),
          InsertionOrder_Pacing_PacingType.PACING_TYPE_EVEN);
    });

    test('NOT_SUPPORTED', () {
      type = 'NOT_SUPPORTED';
      expect(() => Parser.createPacingType(type), throwsFormatException);
    });

    test('null entry', () {
      expect(() => Parser.createPacingType(null), throwsFormatException);
    });
  });

  group('parsing string to InsertionOrder_InsertionOrderBudget_BudgetUnit', () {
    String unit;

    test('BUDGET_UNIT_UNSPECIFIED', () {
      unit = 'BUDGET_UNIT_UNSPECIFIED';
      expect(
          Parser.createBudgetUnit(unit),
          InsertionOrder_InsertionOrderBudget_BudgetUnit
              .BUDGET_UNIT_UNSPECIFIED);
    });

    test('BUDGET_UNIT_CURRENCY', () {
      unit = 'BUDGET_UNIT_CURRENCY';
      expect(Parser.createBudgetUnit(unit),
          InsertionOrder_InsertionOrderBudget_BudgetUnit.BUDGET_UNIT_CURRENCY);
    });

    test('BUDGET_UNIT_IMPRESSIONS', () {
      unit = 'BUDGET_UNIT_IMPRESSIONS';
      expect(
          Parser.createBudgetUnit(unit),
          InsertionOrder_InsertionOrderBudget_BudgetUnit
              .BUDGET_UNIT_IMPRESSIONS);
    });

    test('NOT_SUPPORTED', () {
      unit = 'NOT_SUPPORTED';
      expect(() => Parser.createBudgetUnit(unit), throwsFormatException);
    });

    test('null entry', () {
      expect(() => Parser.createBudgetUnit(null), throwsFormatException);
    });
  });

  group(
      'parsing string to'
      'InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType', () {
    String type;

    test('INSERTION_ORDER_AUTOMATION_TYPE_NONE', () {
      type = 'INSERTION_ORDER_AUTOMATION_TYPE_NONE';
      expect(
          Parser.createAutomationType(type),
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE);
    });

    test('INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED', () {
      type = 'INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED';
      expect(
          Parser.createAutomationType(type),
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED);
    });

    test('INSERTION_ORDER_AUTOMATION_TYPE_BUDGET', () {
      type = 'INSERTION_ORDER_AUTOMATION_TYPE_BUDGET';
      expect(
          Parser.createAutomationType(type),
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BUDGET);
    });

    test('INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET', () {
      type = 'INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET';
      expect(
          Parser.createAutomationType(type),
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_BID_BUDGET);
    });

    test('NOT_SUPPORTED', () {
      type = 'NOT_SUPPORTED';
      expect(() => Parser.createAutomationType(type), throwsFormatException);
    });

    test('null entry', () {
      expect(
          Parser.createAutomationType(null),
          InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
              .INSERTION_ORDER_AUTOMATION_TYPE_NONE);
    });
  });
}
