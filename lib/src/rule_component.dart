import 'package:angular/angular.dart';

import 'data_model/rule.pb.dart';
import 'rule_creator_component.dart';
import 'rule_detail_component.dart';
import 'rule_list_component.dart';

enum View {
  listView,
  createView,
  detailView,
}

@Component(
  selector: 'rule',
  templateUrl: 'rule_component.html',
  directives: [
    coreDirectives,
    RuleListComponent,
    RuleCreatorComponent,
    RuleDetailComponent,
  ],
  exports: [View],
)
class RuleComponent {
  View view = View.listView;
  Rule detailedRule;

  void toCreateView() {
    view = View.createView;
  }

  void toListView() {
    view = View.listView;
  }

  void toDetailView() {
    view = View.detailView;
  }

  Future<void> changeDetailedRule(Rule rule) async {
    detailedRule = rule;
    toDetailView();
  }
}
