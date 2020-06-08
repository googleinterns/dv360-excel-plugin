import 'dart:js';
import 'package:dv360_excel_plugin/js/office_js.dart';
import 'package:dv360_excel_plugin/js/excel_js.dart';

class Excel {
  Excel._private();

  static final Excel _singleton = Excel._private();

  factory Excel() {
    return _singleton;
  }

  void exec() async {
    try {
      await onReady(allowInterop((info) async {
        await run(allowInterop(populate));
      }));
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> populate(RequestContext context) async {
    var sheet = context.workbook.worksheets.getActiveWorksheet();
    var range = sheet.getRange('A1:E1');
    var values = <List<int>>[
      [1, 2, 3, 4, 5]
    ];
    range.values = values;
    range.format.autofitColumns();
    await context.sync();
  }
}

