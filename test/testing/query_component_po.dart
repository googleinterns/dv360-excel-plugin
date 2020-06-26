import 'package:pageloader/pageloader.dart';

part 'query_component_po.g.dart';

@PageObject()
abstract class QueryComponentPageObject {
  QueryComponentPageObject();
  factory QueryComponentPageObject.create(PageLoaderElement context) =
      $QueryComponentPageObject.create;

  @ByDebugId('populate-btn')
  PageLoaderElement get _button;

  @ByDebugId('advertiser-id-input')
  PageLoaderElement get _advertiserInput;

  @ByDebugId('io-id-input')
  PageLoaderElement get _insertionOrderInput;

  Future<void> clickPopulate() async => _button.click();

  Future<void> typeAdvertiserId(String id) async => _advertiserInput.type(id);

  Future<void> clearAdvertiserId() async => _advertiserInput.clear();

  Future<void> typeInsertionOrderId(String id) async =>
      _insertionOrderInput.type(id);

  Future<void> clearInsertionOrderId() async => _insertionOrderInput.clear();
}
