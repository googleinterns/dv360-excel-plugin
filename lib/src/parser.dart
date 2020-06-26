import 'dart:convert';

import 'proto/insertion_order.pb.dart';

class Parser {
  /// Parses a json string to [InsertionOrder].
  static InsertionOrder ioFromJson(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    return createInsertionOrder(map);
  }

  /// Creates an [InsertionOrder] instance from [map].
  ///
  /// Throws an [FormatException] if a required field is missing.
  static InsertionOrder createInsertionOrder(Map<String, dynamic> map) {
    final insertionOrder = InsertionOrder();

    if (!map.containsKey('advertiserId')) throw FormatException;
    insertionOrder.advertiserId = map['advertiserId'];

    if (!map.containsKey('campaignId')) throw FormatException;
    insertionOrder.campaignId = map['campaignId'];

    if (!map.containsKey('insertionOrderId')) throw FormatException;
    insertionOrder.insertionOrderId = map['insertionOrderId'];

    if (!map.containsKey('displayName')) throw FormatException;
    insertionOrder.displayName = map['displayName'];

    if (!map.containsKey('updateTime')) throw FormatException;
    insertionOrder.updateTime = map['updateTime'];

    if (!map.containsKey('entityStatus')) throw FormatException;
    insertionOrder.entityStatus = createEntityStatus(map['entityStatus']);

    if (!map.containsKey('pacing')) throw FormatException;
    insertionOrder.pacing = createPacing(map['pacing']);

    if (!map.containsKey('budget')) throw FormatException;
    insertionOrder.budget = createBudget(map['budget']);
    return insertionOrder;
  }

  /// Creates an [InsertionOrder_Pacing] instance from [map].
  ///
  /// Throws an [FormatException] if a required field is missing or if
  /// both `dailyMaxMicros` and `dailyMaxImpressions` are present.
  static InsertionOrder_Pacing createPacing(Map<String, dynamic> map) {
    final pacing = InsertionOrder_Pacing();

    if (!map.containsKey('pacingPeriod')) throw FormatException;

    pacing.pacingPeriod = createPacingPeriod(map['pacingPeriod']);

    if (!map.containsKey('pacingType')) throw FormatException;
    pacing.pacingType = createPacingType(map['pacingType']);

    if (map.containsKey('dailyMaxMicros') &&
        map.containsKey('dailyMaxImpressions')) {
      throw FormatException;
    } else if (map.containsKey('dailyMaxMicros')) {
      pacing.dailyMaxMicros = map['dailyMaxMicros'];
    } else if (map.containsKey('dailyMaxImpressions')) {
      pacing.dailyMaxImpressions = map['dailyMaxImpressions'];
    }

    return pacing;
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget] from [map].
  ///
  /// Throws an [FormatException] if a required field is missing.
  static InsertionOrder_InsertionOrderBudget createBudget(
      Map<String, dynamic> map) {
    final budget = InsertionOrder_InsertionOrderBudget();

    if (!map.containsKey('budgetUnit')) throw FormatException;
    budget.budgetUnit = createBudgetUnit(map['budgetUnit']);

    budget.automationType = createAutomationType(map['automationType']);

    if (!map.containsKey('budgetSegments')) throw FormatException;
    for (var map in map['budgetSegments']) {
      budget.budgetSegments.add(createBudgetSegment(map));
    }
    return budget;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment]
  /// instance from [map].
  ///
  /// Throws an [FormatException] if a required field is missing.
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment
      createBudgetSegment(Map<String, dynamic> map) {
    final budgetSegment =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment();

    if (!map.containsKey('budgetAmountMicros')) throw FormatException;
    budgetSegment.budgetAmountMicros = map['budgetAmountMicros'];

    if (map.containsKey('description')) {
      budgetSegment.description = map['description'];
    }

    if (!map.containsKey('dateRange')) throw FormatException;
    budgetSegment.dateRange = createDateRange(map['dateRange']);

    if (map.containsKey('campaignBudgetId')) {
      budgetSegment.campaignBudgetId = map['campaignBudgetId'];
    }
    return budgetSegment;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange]
  /// instance from [map].
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange
      createDateRange(Map<String, dynamic> map) {
    final dateRange =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange();

    if (map.containsKey('startDate')) {
      dateRange.startDate = createDate(map['startDate']);
    }

    if (map.containsKey('endDate')) {
      dateRange.endDate = createDate(map['endDate']);
    }

    return dateRange;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date]
  /// from [map].
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date
      createDate(Map<String, dynamic> map) {
    final date =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date();
    if (map.containsKey('year')) date.year = map['year'];
    if (map.containsKey('month')) date.month = map['month'];
    if (map.containsKey('day')) date.day = map['day'];
    return date;
  }

  /// Creates an [InsertionOrder_EntityStatus] enum from [map].
  ///
  /// Throws an [FormatException] if [target] doesn't correspond
  /// to any enum values.
  static InsertionOrder_EntityStatus createEntityStatus(String target) {
    for (var status in InsertionOrder_EntityStatus.values) {
      if (status.name == target) {
        return status;
      }
    }
    throw FormatException();
  }

  /// Creates an [InsertionOrder_Pacing_PacingPeriod] enum from [map].
  ///
  /// Throws an [FormatException] if [target] doesn't correspond
  /// to any enum values.
  static InsertionOrder_Pacing_PacingPeriod createPacingPeriod(String target) {
    for (var period in InsertionOrder_Pacing_PacingPeriod.values) {
      if (period.name == target) {
        return period;
      }
    }
    throw FormatException();
  }

  /// Creates an [InsertionOrder_Pacing_PacingType] enum from [map].
  ///
  /// Throws an [FormatException] if [target] doesn't correspond
  /// to any enum values.
  static InsertionOrder_Pacing_PacingType createPacingType(String target) {
    for (var type in InsertionOrder_Pacing_PacingType.values) {
      if (type.name == target) {
        return type;
      }
    }
    throw FormatException();
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget_BudgetUnit] from [map].
  ///
  /// Throws an [FormatException] if [target] doesn't correspond
  /// to any enum values.
  static InsertionOrder_InsertionOrderBudget_BudgetUnit createBudgetUnit(
      String target) {
    for (var unit in InsertionOrder_InsertionOrderBudget_BudgetUnit.values) {
      if (unit.name == target) {
        return unit;
      }
    }
    throw FormatException();
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType] enum
  /// from [map].
  ///
  /// Throws an [FormatException] if [target] doesn't correspond
  /// to any enum values.
  static InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
      createAutomationType(String target) {
    if (target == null) {
      return InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
          .INSERTION_ORDER_AUTOMATION_TYPE_NONE;
    }

    for (var type
        in InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
            .values) {
      if (type.name == target) {
        return type;
      }
    }
    throw FormatException();
  }
}
