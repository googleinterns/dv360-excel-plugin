import 'package:angular/angular.dart';

import 'rule_creator_component.dart';
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
  ],
  exports: [View],
)
class RuleComponent {
  View view = View.listView;

  void toCreateView() {
    view = View.createView;
  }

  void toListView() {
    view = View.listView;
  }
}
