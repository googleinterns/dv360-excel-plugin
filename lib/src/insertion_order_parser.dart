import 'dart:convert';

import 'proto/insertion_order.pb.dart';

class InsertionOrderParser {
  static const _emptyEntry = '';

  // Disregarding linter rule to ensure that enum maps are typed.
  static final _entityStatusMap =
      Map<String, InsertionOrder_EntityStatus>.fromIterable(
          InsertionOrder_EntityStatus.values,
          key: (v) => v.name,
          value: (v) => v);

  static final _pacingPeriodMap =
      Map<String, InsertionOrder_Pacing_PacingPeriod>.fromIterable(
          InsertionOrder_Pacing_PacingPeriod.values,
          key: (v) => v.name,
          value: (v) => v);

  static final _pacingTypeMap =
      Map<String, InsertionOrder_Pacing_PacingType>.fromIterable(
          InsertionOrder_Pacing_PacingType.values,
          key: (v) => v.name,
          value: (v) => v);

  static final _budgetUnitMap =
      Map<String, InsertionOrder_Budget_BudgetUnit>.fromIterable(
          InsertionOrder_Budget_BudgetUnit.values,
          key: (v) => v.name,
          value: (v) => v);

  static final _automationTypeMap = Map<String,
          InsertionOrder_Budget_InsertionOrderAutomationType>.fromIterable(
      InsertionOrder_Budget_InsertionOrderAutomationType.values,
      key: (v) => v.name,
      value: (v) => v);

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
  static InsertionOrder_Budget _createBudget(Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_Budget();
    }

    final budget = InsertionOrder_Budget()
      ..budgetUnit = _createBudgetUnit(map['budgetUnit'])
      ..automationType = _createAutomationType(map['automationType']);

    for (Map segmentMap in map['budgetSegments'] ?? []) {
      budget.budgetSegments.add(_createBudgetSegment(segmentMap));
    }
    return budget;
  }

  static InsertionOrder_Budget_BudgetSegment _createBudgetSegment(
      Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_Budget_BudgetSegment();
    }

    final budgetSegment = InsertionOrder_Budget_BudgetSegment()
      ..budgetAmountMicros = map['budgetAmountMicros'] ?? _emptyEntry
      ..description = map['description'] ?? _emptyEntry
      ..campaignBudgetId = map['campaignBudgetId'] ?? _emptyEntry
      ..dateRange = _createDateRange(map['dateRange']);

    return budgetSegment;
  }

  static InsertionOrder_Budget_BudgetSegment_DateRange _createDateRange(
      Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_Budget_BudgetSegment_DateRange();
    }

    final dateRange = InsertionOrder_Budget_BudgetSegment_DateRange()
      ..startDate = _createDate(map['startDate'])
      ..endDate = _createDate(map['endDate']);

    return dateRange;
  }

  static InsertionOrder_Budget_BudgetSegment_DateRange_Date _createDate(
      Map<String, dynamic> map) {
    if (map == null || map.isEmpty) {
      return InsertionOrder_Budget_BudgetSegment_DateRange_Date();
    }

    final date = InsertionOrder_Budget_BudgetSegment_DateRange_Date()
      ..year = map['year'] ?? _emptyEntry
      ..month = map['month'] ?? _emptyEntry
      ..day = map['day'] ?? _emptyEntry;

    return date;
  }

  static InsertionOrder_EntityStatus _createEntityStatus(String target) =>
      _entityStatusMap[target] ?? InsertionOrder_EntityStatus.valueOf(0);

  static InsertionOrder_Pacing_PacingPeriod _createPacingPeriod(
          String target) =>
      _pacingPeriodMap[target] ?? InsertionOrder_Pacing_PacingPeriod.valueOf(0);

  static InsertionOrder_Pacing_PacingType _createPacingType(String target) =>
      _pacingTypeMap[target] ?? InsertionOrder_Pacing_PacingType.valueOf(0);

  static InsertionOrder_Budget_BudgetUnit _createBudgetUnit(String target) =>
      _budgetUnitMap[target] ?? InsertionOrder_Budget_BudgetUnit.valueOf(0);

  static InsertionOrder_Budget_InsertionOrderAutomationType
      _createAutomationType(String target) {
    /// Returns default value if [target] is null
    if (target == null) {
      return InsertionOrder_Budget_InsertionOrderAutomationType.valueOf(0);
    }

    /// Returns [INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED]
    /// if [target] doesn't correspond to any enum values.
    return _automationTypeMap[target] ??
        InsertionOrder_Budget_InsertionOrderAutomationType
            .INSERTION_ORDER_AUTOMATION_TYPE_UNSPECIFIED;
  }
}
