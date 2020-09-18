@JS('cronstrue')
library cronstrue;

import 'package:js/js.dart';
import 'package:angular/angular.dart';
import 'package:proto/rule.pb.dart';

@JS('toString')
external String toString(String obj);

@Injectable()
class ScheduleParser {
  String scheduleToString(Schedule schedule) {
    if (schedule.type == Schedule_Type.REPEATING) {
      return toString(schedule.repeatingParams.cronExpression);
    } else {
      return '';
    }
  }
}
