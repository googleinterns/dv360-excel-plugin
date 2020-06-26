import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';

import 'query_builder.dart';
import 'query_service.dart';

@Component(
  selector: 'query',
  template: '''
    <input [(ngModel)]="queryBuilder.advertiserId" 
           placeholder="Advertiser ID: 164337" debugId="advertiser-id-input">
    <input [(ngModel)]="queryBuilder.insertionOrderId" 
           placeholder="Insertion Order ID: 8127549" debugId="io-id-input">
    <button (click)="onClick()" debugId="populate-btn">
    {{buttonName}}
    </button>
  ''',
  providers: [ClassProvider(QueryBuilder), ClassProvider(QueryService)],
  directives: [formDirectives],
)
class QueryComponent {
  final buttonName = 'populate';
  final QueryBuilder queryBuilder;
  final QueryService queryService;

  QueryComponent(this.queryBuilder, this.queryService);

  void onClick() => queryService.execQuery();
}
