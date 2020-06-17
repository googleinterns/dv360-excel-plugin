import 'package:pageloader/pageloader.dart';

part 'query_component_po.g.dart';

@PageObject()
abstract class QueryComponentPageObject {
  QueryComponentPageObject();
  factory QueryComponentPageObject.create(PageLoaderElement context) =
      $QueryComponentPageObject.create;

  @ByTagName('material-button')
  @WithVisibleText('populate')
  PageLoaderElement get _button;

  Future<void> populate() async => _button.click();
}
