import 'dart:js';

import 'gapi.dart';
import 'json_js.dart';
import 'insertion_order_parser.dart';
import 'proto/insertion_order.pb.dart';
import 'dv360_query_builder.dart';

class QueryService {
  QueryService._private();

  static final QueryService _singleton = QueryService._private();

  factory QueryService() {
    return _singleton;
  }

  final queryBuilder = DV360QueryBuilder();
  final _table = <InsertionOrder>[];

  /// Executes the query and passes the returned result to the parser.
  void execQuery() async {
    final requestArgs =
        RequestArgs(path: queryBuilder.generateQuery(), method: 'GET');

    await GoogleAPI.client.request(requestArgs).then(allowInterop((response) {
      final rawResponse = stringify(response.result);
      _table.add(InsertionOrderParser.parse(rawResponse));
    }));
  }
}
