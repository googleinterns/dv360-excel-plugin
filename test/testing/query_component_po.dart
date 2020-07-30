import 'package:pageloader/pageloader.dart';

part 'query_component_po.g.dart';

@PageObject()
abstract class QueryComponentPageObject {
  QueryComponentPageObject();
  factory QueryComponentPageObject.create(PageLoaderElement context) =
      $QueryComponentPageObject.create;

  @ByDebugId('populate-btn')
  PageLoaderElement get _populateButton;

  @ByDebugId('populate-btn-spinner')
  PageLoaderElement get populateButtonSpinner;

  @ByDebugId('underpacing-checkbox')
  PageLoaderElement get _underpacingCheckBox;

  @ByDebugId('query-alert')
  PageLoaderElement get queryAlert;

  Future<void> selectUnderpacing() async => _underpacingCheckBox.click();

  Future<String> getAlertMessage() async => queryAlert.innerText;

  Future<void> clickPopulate() async => _populateButton.click();
}

@PageObject()
abstract class QueryComponentAccordionPageObject {
  QueryComponentAccordionPageObject();

  factory QueryComponentAccordionPageObject.create(PageLoaderElement context) =
      $QueryComponentAccordionPageObject.create;

  @ById('by-advertiser-panel')
  PageLoaderElement get _byAdvertiserPanel;

  @ById('by-media-plan-panel')
  PageLoaderElement get _byMediaPlanPanel;

  @ById('by-io-panel')
  PageLoaderElement get _byInsertionOrderPanel;

  @ByTagName('div')
  @WithAttribute('aria-hidden', 'false')
  PageLoaderElement get _visibleAccordionPanel;

  PageLoaderElement get _advertiserIdInputBox =>
      _visibleAccordionPanel.byTag('input');

  @ByDebugId('media-plan-id-input')
  PageLoaderElement get _mediaPlanIdInputBox;

  @ByDebugId('io-id-input')
  PageLoaderElement get _insertionOrderIdInputBox;

  Future<void> selectByAdvertiser() async => _byAdvertiserPanel.click();

  Future<void> selectByMediaPlan() async => _byMediaPlanPanel.click();

  Future<void> selectByIO() async => _byInsertionOrderPanel.click();

  Future<void> typeAdvertiserId(String id) async =>
      _advertiserIdInputBox.type(id);

  Future<void> typeMediaPlanId(String id) async =>
      _mediaPlanIdInputBox.type(id);

  Future<void> typeInsertionOrderId(String id) async =>
      _insertionOrderIdInputBox.type(id);
}
