@JS()
library stringify;
import 'package:js/js.dart';

/// Wrapper function for JSON.stringify()

/// ``` javascript function
///   JSON.stringify()
/// ```
@JS('JSON.stringify')
external String stringify(Object obj);