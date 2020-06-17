import 'package:pageloader/pageloader.dart';

part 'root_component_po.g.dart';

@PageObject()
abstract class RootComponentPageObject {
  RootComponentPageObject();
  factory RootComponentPageObject.create(PageLoaderElement context) =
      $RootComponentPageObject.create;

  @ByTagName('h2')
  PageLoaderElement get _title;

  String get title => _title.visibleText;
}
