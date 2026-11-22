import 'dart:js_interop';

@JS('groundsetPush.status')
external JSString? _status();

@JS('groundsetPush.an')
external JSPromise<JSString?> _an(JSString schluessel);

String pushStatus() {
  try {
    return _status()?.toDart ?? 'aus';
  } catch (_) {
    return 'aus';
  }
}

Future<String?> pushAn(String schluessel) async {
  try {
    return (await _an(schluessel.toJS).toDart)?.toDart;
  } catch (_) {
    return null;
  }
}
