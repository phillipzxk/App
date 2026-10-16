import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Takes one photo and returns it as JPEG bytes, or null when cancelled.
typedef FotoAufnahme = Future<Uint8List?> Function();

/// Opens the camera (in the browser preview: the file picker). The photo is
/// scaled down so many weeks fit on the phone. Replaced in tests.
///
/// The camera with the outline of the first photo and the automatic shot at
/// exactly the same position comes with the phone version of the app.
FotoAufnahme fotoAufnahme = () async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 900,
    imageQuality: 75,
  );
  return file?.readAsBytes();
};
