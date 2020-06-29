import 'dart:convert';

import 'proto/insertion_order.pb.dart';

class InsertionOrderParser {
  static const _emptyEntry = '';

  static final _entityStatusMap = {
    for (var status in InsertionOrder_EntityStatus.values) status.name: status
  };

  static final _pacingPeriodMap = {
    for (var period in InsertionOrder_Pacing_PacingPeriod.values)
      period.name: period
  };

  static final _pacingTypeMap = {
    for (var type in InsertionOrder_Pacing_PacingType.values) type.name: type
  };

  static final _budgetUnitMap = {
    for (var unit in InsertionOrder_InsertionOrderBudget_BudgetUnit.values)
      unit.name: unit
  };

  static final _automationTypeMap = {
    for (var type
        in InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
            .values)
      type.name: type
  };

  /// Parses a json string to [InsertionOrder].
  static InsertionOrder parse(String jsonString) {
    Map<String, dynamic> map = json.decode(jsonString);
    return _createInsertionOrder(map);
  }

  /// Creates an [InsertionOrder] instance from [map].
  static InsertionOrder _createInsertionOrder(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) return InsertionOrder();

    final insertionOrder = InsertionOrder()
      ..advertiserId = map['advertiserId'] ?? _emptyEntry
      ..campaignId = map['campaignId'] ?? _emptyEntry
      ..insertionOrderId = map['insertionOrderId'] ?? _emptyEntry
      ..displayName = map['displayName'] ?? _emptyEntry
      ..updateTime = map['updateTime'] ?? _emptyEntry
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
      ..dailyMaxMicros = map['dailyMaxMicros'] ?? _emptyEntry
      ..dailyMaxImpressions = map['dailyMaxImpressions'] ?? _emptyEntry;

    return pacing;
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget] instance from [map].
  static InsertionOrder_InsertionOrderBudget _createBudget(
      Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_InsertionOrderBudget();
    }

    final budget = InsertionOrder_InsertionOrderBudget()
      ..budgetUnit = _createBudgetUnit(map['budgetUnit'])
      ..automationType = _createAutomationType(map['automationType']);

    for (Map segmentMap in map['budgetSegments'] ?? []) {
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
          ..budgetAmountMicros = map['budgetAmountMicros'] ?? _emptyEntry
          ..description = map['description'] ?? _emptyEntry
          ..campaignBudgetId = map['campaignBudgetId'] ?? _emptyEntry
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
          ..year = map['year'] ?? _emptyEntry
          ..month = map['month'] ?? _emptyEntry
          ..day = map['day'] ?? _emptyEntry;

    return date;
  }

  /// Creates an [InsertionOrder_EntityStatus] enum from [map].
  ///
  /// Returns default value [ENTITY_STATUS_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_EntityStatus _createEntityStatus(String target) {
    if (_entityStatusMap.containsKey(target)) return _entityStatusMap[target];
    return InsertionOrder_EntityStatus.ENTITY_STATUS_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_Pacing_PacingPeriod] enum from [map].
  ///
  /// Returns default value [PACING_PERIOD_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_Pacing_PacingPeriod _createPacingPeriod(String target) {
    if (_pacingPeriodMap.containsKey(target)) return _pacingPeriodMap[target];
    return InsertionOrder_Pacing_PacingPeriod.PACING_PERIOD_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_Pacing_PacingType] enum from [map].
  ///
  /// Returns default value [PACING_TYPE_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_Pacing_PacingType _createPacingType(String target) {
    if (_pacingTypeMap.containsKey(target)) return _pacingTypeMap[target];
    return InsertionOrder_Pacing_PacingType.PACING_TYPE_UNSPECIFIED;
  }

  /// Creates an [InsertionOrder_InsertionOrderBudget_BudgetUnit] from [map].
  ///
  /// Returns default value [BUDGET_UNIT_UNSPECIFIED]
  /// if [target] doesn't correspond to any enum values.
  static InsertionOrder_InsertionOrderBudget_BudgetUnit _createBudgetUnit(
      String target) {
    if (_budgetUnitMap.containsKey(target)) return _budgetUnitMap[target];
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

    if (_automationTypeMap.containsKey(target)) {
      return _automationTypeMap[target];
    }

    return InsertionOrder_InsertionOrderBudget_InsertionOrderAutomationType
        .INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED;
  }
}
