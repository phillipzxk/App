import 'dart:js_interop';

import 'package:web/web.dart' as web;

Uri? aktuelleAdresse() => Uri.tryParse(web.window.location.href);

/// Removes the session from the address bar after Apple or Google.
void adresseAufraeumen() {
  final l = web.window.location;
  web.window.history.replaceState(null, '', '${l.pathname}${l.search}');
}

void zuAdresse(Uri adresse) => web.window.location.href = '$adresse';

bool dateiSpeichern(String name, String inhalt) {
  final blob = web.Blob(
    [inhalt.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  a.click();
  web.URL.revokeObjectURL(url);
  return true;
}
