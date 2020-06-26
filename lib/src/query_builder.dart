enum QueryType { singleIO }

class QueryBuilder {
  QueryBuilder._private();

  static final QueryBuilder _singleton = QueryBuilder._private();

  factory QueryBuilder() {
    return _singleton;
  }

  final _queryPrefix = 'https://displayvideo.googleapis.com/v1';
  final _advertiserPrefix = 'advertisers';
  final _insertionOrderPrefix = 'insertionOrders';

  // Currently, query type is default to singleIO.
  final _queryType = QueryType.singleIO;

  String _advertiserId;
  String _insertionOrderId;

  String get advertiserId => _advertiserId;
  set advertiserId(String id) => _advertiserId = id;

  String get insertionOrderId => _insertionOrderId;
  set insertionOrderId(String id) => _insertionOrderId = id;

  /// Generates query based on user selected query type and inputs.
  String generateQuery() {
    String query;

    if (_queryType == QueryType.singleIO) {
      query = '$_queryPrefix/$_advertiserPrefix/$_advertiserId/'
          '$_insertionOrderPrefix/$_insertionOrderId';
    }

    return query;
  }
}
