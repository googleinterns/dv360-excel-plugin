import 'package:pageloader/pageloader.dart';

part 'query_component_radio_button_po.g.dart';

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
