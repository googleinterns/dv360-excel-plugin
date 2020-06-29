import 'dart:convert';

import 'proto/insertion_order.pb.dart';

class InsertionOrderParser {
  static const emptyEntry = '';

  /// Parses a json string to [InsertionOrder].
  static InsertionOrder parse(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    return _createInsertionOrder(map);
  }

  /// Creates an [InsertionOrder] instance from [map].
  static InsertionOrder _createInsertionOrder(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) return InsertionOrder();

    final insertionOrder = InsertionOrder()
      ..advertiserId = map['advertiserId'] ?? emptyEntry
      ..campaignId = map['campaignId'] ?? emptyEntry
      ..insertionOrderId = map['insertionOrderId'] ?? emptyEntry
      ..displayName = map['displayName'] ?? emptyEntry
      ..updateTime = map['updateTime'] ?? emptyEntry
      ..entityStatus = _createEntityStatus(map['entityStatus'])
      ..pacing = _createPacing(map['pacing'])
      ..budget = _createBudget(map['budget']);

    return insertionOrder;
  }

  /// Creates an [InsertionOrder_Pacing] instance from [map].
  static InsertionOrder_Pacing _createPacing(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) return InsertionOrder_Pacing();

    final pacing = InsertionOrder_Pacing()
      ..pacingPeriod = _createPacingPeriod(map['pacingPeriod'])
      ..pacingType = _createPacingType(map['pacingType'])
      ..dailyMaxMicros = map['dailyMaxMicros'] ?? emptyEntry
      ..dailyMaxImpressions = map['dailyMaxImpressions'] ?? emptyEntry;

    return pacing;
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget] instance from [map].
  static InsertionOrder_InsertionOrderBudget _createBudget(
      Map<String, dynamic> map) {
    if (map == null || map.isEmpty)
      return InsertionOrder_InsertionOrderBudget();

    final budget = InsertionOrder_InsertionOrderBudget()
      ..budgetUnit = _createBudgetUnit(map['budgetUnit'])
      ..automationType = _createAutomationType(map['automationType']);

    for (var segmentMap in map['budgetSegments'] ?? []) {
      budget.budgetSegments.add(_createBudgetSegment(segmentMap));
    }
    return budget;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment]
  /// instance from [map].
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment
      _createBudgetSegment(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment();
    }

    final budgetSegment =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment()
          ..budgetAmountMicros = map['budgetAmountMicros'] ?? emptyEntry
          ..description = map['description'] ?? emptyEntry
          ..campaignBudgetId = map['campaignBudgetId'] ?? emptyEntry
          ..dateRange = _createDateRange(map['dateRange']);

    return budgetSegment;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange]
  /// instance from [map].
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange
      _createDateRange(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange();
    }

    final dateRange =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange()
          ..startDate = _createDate(map['startDate'])
          ..endDate = _createDate(map['endDate']);

    return dateRange;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date]
  /// instance from [map].
  static InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date
      _createDate(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date();
    }

    final date =
        InsertionOrder_InsertionOrderBudget_InsertionOrderBudgetSegment_DateRange_Date()
          ..year = map['year'] ?? emptyEntry
          ..month = map['month'] ?? emptyEntry
          ..day = map['day'] ?? emptyEntry;

    return date;
  }

  /// Creates an [InsertionOrder_EntityStatus] enum from [map].
  ///
  /// Returns default value [ENTITY_STATUS_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_EntityStatus _createEntityStatus(String target) {
    for (var status in InsertionOrder_EntityStatus.values) {
      if (status.name == target) {
        return status;
      }
    }
    return InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_Pacing_PacingPeriod] enum from [map].
  ///
  /// Returns default value [PACING_PERIOD_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_Pacing_PacingPeriod _createPacingPeriod(String target) {
    for (var period in InsertionOrder_Pacing_PacingPeriod.values) {
      if (period.name == target) {
        return period;
      }
    }
    return InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_Pacing_PacingType] enum from [map].
  ///
  /// Returns default value [PACING_TYPE_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_Pacing_PacingType _createPacingType(String target) {
    for (var type in InsertionOrder_Pacing_PacingType.values) {
      if (type.name == target) {
        return type;
      }
    }
    return InsertionOrder_Pacing_PacingType.PACING_TYPE_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget_BudgetUnit] from [map].
  ///
  /// Returns default value [BUDGET_UNIT_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_InsertionOrderBudget_BudgetUnit _createBudgetUnit(
      String target) {
    for (var unit in InsertionOrder_InsertionOrderBudget_BudgetUnit.values) {
      if (unit.name == target) {
        return unit;
      }
    }
    return InsertionOrder_InsertionOrderBudget_BudgetUnit
        .BUDGET_UNIT_UNSPECIFIED;
  }

  /// Creates an
  /// [InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType] enum
  /// from [map].
  ///
  /// Returns [INSERTION_ORDER_AUTOMATION_TYPE_NONE] if [target] is null.
  /// Returns default value [INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
      _createAutomationType(String target) {
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

    return InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
        .INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED;
  }
}
