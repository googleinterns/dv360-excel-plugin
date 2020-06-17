import 'dart:html';

/// Injects corresponding JS library before running component tests.
class JSInjector {
  static ScriptElement _script;

  static final _officeScript =
      'https://appsforoffice.microsoft.com/lib/1/hosted/office.js';
  static final _googleScript = 'https://apis.google.com/js/api.js';
  static final _type = 'text/javascript';

  /// Injects Office JS library script
  static void injectOfficeJS() {
    _script = ScriptElement();
    _script.src = _officeScript;
    _script.type = _type;
    _script.async = true;
    _script.defer = true;
    // insert before the first script element in header
    document.head.insertBefore(_script, querySelector('script'));
  }

  /// Injects Google JS library script
  static void injectGoogleJS() {
    _script = ScriptElement();
    _script.src = _googleScript;
    _script.type = _type;
    _script.async = true;
    _script.defer = true;
    // insert before the first script element in header
    document.head.insertBefore(_script, querySelector('script'));
  }
}
