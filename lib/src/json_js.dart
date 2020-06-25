@JS('JSON')
library stringify;

import 'package:js/js.dart';

/// Native JSON library is used to parse the returned value of
/// gapi.client.request(), which is a JS JSON object.

/// Wrapper function for JSON.stringify().
///
/// ``` js
///   JSON.stringify()
/// ```
@JS('stringify')
external String stringify(Object obj);
