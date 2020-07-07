import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

import 'excel.dart';
import 'insertion_order_parser.dart';
import 'json_js.dart';
import 'query_service.dart';

@Component(
  selector: 'query',
  template: '''
    <input [(ngModel)]="advertiserId" 
           placeholder="Advertiser ID: 164337" debugId="advertiser-id-input">
    <input [(ngModel)]="insertionOrderId" 
           placeholder="Insertion Order ID: 8127549" debugId="io-id-input">
    <button (click)="onClick()" debugId="populate-btn">
    {{buttonName}}
    </button>
  ''',
  providers: [ClassProvider(QueryService)],
  directives: [formDirectives],
)
class QueryComponent {
  final buttonName = 'populate';
  final QueryService _queryService;

  String advertiserId;
  String insertionOrderId;

  QueryComponent(this._queryService);

  void onClick() async {
    final jsonResponse =
        await _queryService.execQuery(advertiserId, insertionOrderId);
    final parsedResponse = InsertionOrderParser.parse(stringify(jsonResponse));
    await ExcelDart.populate([parsedResponse]);
  }
}
