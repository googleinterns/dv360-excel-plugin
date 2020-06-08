@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:dv360_excel_plugin/app_component.dart';
import 'package:dv360_excel_plugin/app_component.template.dart' as ng;
import 'package:test/test.dart';

void main() {
  final testBed = NgTestBed.forComponent<AppComponent>(ng.AppComponentNgFactory);
  NgTestFixture<AppComponent> fixture;

  setUp(() async {
    fixture = await testBed.create();
  });

  tearDown(disposeAnyRunningTest);

  test('Default title', () async {
    expect(fixture.text, 'Display & Video 360');
  });

  test('Change title', () async {
    await fixture.update((c) => c.title = 'New Title');
    expect(fixture.text, 'New Title');
  });
}