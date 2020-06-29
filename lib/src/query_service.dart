import 'dart:js';

import 'gapi.dart';
import 'json_js.dart';
import 'insertion_order_parser.dart';
import 'proto/insertion_order.pb.dart';

class QueryService {
  QueryService._private();

  static final QueryService _singleton = QueryService._private();

  factory QueryService() {
    return _singleton;
  }

  final _insertionOrderLists = <InsertionOrder>[];

  /// Executes the query and passes the returned result to the parser.
  void execQuery(String advertiserId, String insertionOrderId) async {
    final requestArgs = RequestArgs(
        path: _generateQuery(advertiserId, insertionOrderId), method: 'GET');

    await GoogleAPI.client.request(requestArgs).then(allowInterop((response) {
      final rawResponse = stringify(response.result);
      _insertionOrderLists.add(InsertionOrderParser.parse(rawResponse));
      print(_insertionOrderLists[0]);
    }));
  }

  /// Generates query based on user inputs.
  String _generateQuery(String advertiserId, String insertionOrderId) {
    return 'https://displayvideo.googleapis.com/v1/advertisers/$advertiserId/'
        'insertionOrders/$insertionOrderId';
  }
}
