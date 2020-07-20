library insertion_order_daily_spend;

import 'package:built_value/built_value.dart';

part 'insertion_order_daily_spend.g.dart';

abstract class InsertionOrderDailySpend
    implements
        Built<InsertionOrderDailySpend, InsertionOrderDailySpendBuilder> {
  DateTime get date;
  String get revenue;
  String get impression;

  InsertionOrderDailySpend._();
  factory InsertionOrderDailySpend(
          [updates(InsertionOrderDailySpendBuilder b)]) =
      _$InsertionOrderDailySpend;
}
