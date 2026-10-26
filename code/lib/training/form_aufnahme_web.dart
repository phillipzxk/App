import 'dart:async';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

/// Records (or picks) a video and takes 4 evenly spread stills from it,
/// about 480 px wide, so they are small enough to keep and to send.
Future<List<String>?> formStandbilder() async {
  final file = await ImagePicker().pickVideo(
    source: ImageSource.camera,
    maxDuration: const Duration(seconds: 60),
  );
  if (file == null) return null;
  try {
    final video = web.HTMLVideoElement()
      ..muted = true
      ..preload = 'auto'
      ..src = file.path;
    await web.EventStreamProviders.loadedMetadataEvent
        .forTarget(video)
        .first
        .timeout(const Duration(seconds: 20));
    final dauer = video.duration;
    if (!dauer.isFinite || dauer <= 0) return null;
    final breite = 480;
    final hoehe = video.videoWidth == 0
        ? 640
        : (video.videoHeight * breite / video.videoWidth).round();
    final canvas = web.HTMLCanvasElement()
      ..width = breite
      ..height = hoehe;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    final bilder = <String>[];
    for (final anteil in const [0.12, 0.38, 0.62, 0.88]) {
      final gesucht = web.EventStreamProviders.seekedEvent
          .forTarget(video)
          .first;
      video.currentTime = dauer * anteil;
      await gesucht.timeout(const Duration(seconds: 10));
      ctx.drawImage(video, 0, 0, breite, hoehe);
      final url = canvas.toDataURL('image/jpeg', 0.7.toJS);
      bilder.add(url.substring(url.indexOf(',') + 1));
    }
    return bilder;
  } catch (_) {
    return null;
  }
}
