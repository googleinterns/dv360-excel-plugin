import 'package:pageloader/pageloader.dart';

part 'root_component_po.g.dart';

@PageObject()
abstract class RootComponentLandingPagePageObject {
  RootComponentLandingPagePageObject();
  factory RootComponentLandingPagePageObject.create(PageLoaderElement context) =
      $RootComponentLandingPagePageObject.create;

  @ByDebugId('landing-page')
  PageLoaderElement get landingPage;

  @ByDebugId('welcome-msg')
  PageLoaderElement get welcomeMessage;

  @ByDebugId('sideload-msg')
  PageLoaderElement get sideloadMessage;

  @ByDebugId('sign-on-btn')
  PageLoaderElement get signOnButton;

  Future<void> clickSignOn() async => signOnButton.click();
}

@PageObject()
abstract class RootComponentMainPagePageObject {
  RootComponentMainPagePageObject();
  factory RootComponentMainPagePageObject.create(PageLoaderElement context) =
      $RootComponentMainPagePageObject.create;

  @ByDebugId('main-page')
  PageLoaderElement get mainPage;

  @ByDebugId('sign-off-btn')
  PageLoaderElement get signOffButton;

  Future<void> clickSignOff() async => signOffButton.click();
}
