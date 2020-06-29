import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'package:dv360_excel_plugin/src/dv360_query_builder.dart';

void main() {
  const advertiserId = '111111';
  const insertionOrderId = '2222222';
  DV360QueryBuilder queryBuilder;

  setUp(() {
    queryBuilder = DV360QueryBuilder();
  });

  tearDown(disposeAnyRunningTest);

  group('generate query for:', () {
    setUp(() {
      queryBuilder.advertiserId = advertiserId;
      queryBuilder.insertionOrderId = insertionOrderId;
    });

    test('a single insertion order', () {
      final actual = queryBuilder.generateQuery();

      final expected = 'https://displayvideo.googleapis.com/v1/'
          'advertisers/111111/insertionOrders/2222222';
      expect(actual, expected);
    });
  });
}
