import 'package:pageloader/pageloader.dart';

part 'credential_component_po.g.dart';

@PageObject()
abstract class CredentialComponentPageObject {
  CredentialComponentPageObject();
  factory CredentialComponentPageObject.create(PageLoaderElement context) =
      $CredentialComponentPageObject.create;

  @ByDebugId('sign-on-btn')
  PageLoaderElement get _button;

  Future<void> clickSignOn() async => _button.click();
}
