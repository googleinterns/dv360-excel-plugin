import 'dart:async';
import 'dart:js';

import 'package:angular/angular.dart';

import 'gapi.dart';

@Injectable()
class QueryService {
  /// Executes the query and returns the raw javascript object.
  Future<T> execQuery<T>(String advertiserId, String insertionOrderId) async {
    final requestArgs = RequestArgs(
        path: _generateQuery(advertiserId, insertionOrderId), method: 'GET');

    final responseCompleter = Completer<T>();
    GoogleAPI.client
        .request(requestArgs)
        .execute(allowInterop((jsonResp, rawResp) {
      responseCompleter.complete(jsonResp);
    }));

    return responseCompleter.future;
  }

  /// Generates query based on user inputs.
  static String _generateQuery(String advertiserId, String insertionOrderId) {
    return 'https://displayvideo.googleapis.com/v1/advertisers/$advertiserId/'
        'insertionOrders/$insertionOrderId';
  }
}
