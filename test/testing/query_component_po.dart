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
  PageLoaderElement get _advertiserIdInputBox;

  @ByDebugId('media-plan-id-input')
  PageLoaderElement get _mediaPlanIdInputBox;

  @ByDebugId('io-id-input')
  PageLoaderElement get _insertionOrderIdInputBox;

  @ByDebugId('underpacing-checkbox')
  PageLoaderElement get _underpacingCheckBox;

  Future<void> typeAdvertiserId(String id) async =>
      _advertiserIdInputBox.type(id);

  Future<void> typeMediaPlanId(String id) async =>
      _mediaPlanIdInputBox.type(id);

  Future<void> typeInsertionOrderId(String id) async =>
      _insertionOrderIdInputBox.type(id);

  Future<void> selectUnderpacing() async => _underpacingCheckBox.click();

  Future<void> clickPopulate() async => _button.click();
}

@PageObject()
abstract class QueryComponentRadioButtonPageObject {
  QueryComponentRadioButtonPageObject();

  factory QueryComponentRadioButtonPageObject.create(
      PageLoaderElement context) = $QueryComponentRadioButtonPageObject.create;

  @ById('by-advertiser-radio-btn')
  PageLoaderElement get _byAdvertiserRadioBtn;

  @ById('by-media-plan-radio-btn')
  PageLoaderElement get _byMediaPlanRadioBtn;

  @ById('by-io-radio-btn')
  PageLoaderElement get _byInsertionOrderRadioBtn;

  Future<void> selectByAdvertiser() async => _byAdvertiserRadioBtn.click();

  Future<void> selectByMediaPlan() async => _byMediaPlanRadioBtn.click();

  Future<void> selectByIO() async => _byInsertionOrderRadioBtn.click();
}
