@JS('cronstrue')
library cronstrue;

import 'package:js/js.dart';
import 'package:angular/angular.dart';

import '../data_model/rule.pb.dart';

@JS('toString')
external String toString(String obj);

@Injectable()
class ScheduleParser {
  String scheduleToString(Schedule schedule) {
    switch (schedule.type) {
      case Schedule_Type.REPEATING:
        return toString(schedule.repeatingParams.cronExpression);
      default:
        return '';
    }
  }
}
