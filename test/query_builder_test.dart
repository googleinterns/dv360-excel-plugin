import 'dart:math';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'package:dv360_excel_plugin/src/query_builder.dart';

void main() {
  const max = 10000;

  Random random;
  QueryBuilder queryBuilder;

  setUp(() {
    random = Random();
    queryBuilder = QueryBuilder();
  });

  tearDown(disposeAnyRunningTest);

  group('generate query for:', () {
    String advertiserId;
    String insertionOrderId;

    setUp(() {
      advertiserId = random.nextInt(max).toString();
      insertionOrderId = random.nextInt(max).toString();
      queryBuilder.advertiserId = advertiserId;
      queryBuilder.insertionOrderId = insertionOrderId;
    });

    test('a single insertion order', () {
      final query = 'https://displayvideo.googleapis.com/v1/'
          'advertisers/$advertiserId/insertionOrders/$insertionOrderId';
      expect(queryBuilder.generateQuery(), query);
    });
  });
}
