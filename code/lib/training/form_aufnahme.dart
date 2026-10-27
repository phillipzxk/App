import 'form_aufnahme_stub.dart'
    if (dart.library.js_interop) 'form_aufnahme_web.dart'
    as impl;

/// Films one set and returns a few stills from it as base64 JPEG (oldest
/// first), or null when cancelled or not possible. Replaced in tests.
///
/// In the browser preview the stills are taken from the recorded video.
/// On the phone the full video is kept too once the phone version exists.
typedef FormAufnahme = Future<List<String>?> Function();

FormAufnahme formAufnahme = impl.formStandbilder;
