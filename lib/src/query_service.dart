import 'dart:js';

import 'package:angular/angular.dart';
import 'package:dv360_excel_plugin/src/excel.dart';

import 'gapi.dart';
import 'json_js.dart';
import 'insertion_order_parser.dart';
import 'proto/insertion_order.pb.dart';

@Injectable()
class QueryService {
  static final _insertionOrderLists = <InsertionOrder>[];

  /// Executes the query and passes the returned result to the parser.
  void execQuery(String advertiserId, String insertionOrderId) async {
    final requestArgs = RequestArgs(
        path: _generateQuery(advertiserId, insertionOrderId), method: 'GET');

    await GoogleAPI.client.request(requestArgs).then(allowInterop((response) {
      _insertionOrderLists
          .add(InsertionOrderParser.parse(stringify(response.result)));
      ExcelDart.populate(_insertionOrderLists);
    }));
  }

  /// Generates query based on user inputs.
  static String _generateQuery(String advertiserId, String insertionOrderId) {
    return 'https://displayvideo.googleapis.com/v1/advertisers/$advertiserId/'
        'insertionOrders/$insertionOrderId';
  }
}
