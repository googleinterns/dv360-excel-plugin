import 'package:pageloader/pageloader.dart';

part 'query_component_po.g.dart';

@PageObject()
abstract class QueryComponentPageObject {
  QueryComponentPageObject();
  factory QueryComponentPageObject.create(PageLoaderElement context) =
      $QueryComponentPageObject.create;

  @ByDebugId('populate-btn')
  PageLoaderElement get _button;

  Future<void> clickPopulate() async => _button.click();
}
