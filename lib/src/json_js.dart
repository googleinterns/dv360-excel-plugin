@JS('JSON')
library stringify;

import 'package:js/js.dart';

/// Wrapper function for JSON.stringify()

/// ``` js
///   JSON.stringify()
/// ```
@JS('stringify')
external String stringify(Object obj);
