import 'dart:convert';

import 'chat_push_stub.dart'
    if (dart.library.js_interop) 'chat_push_web.dart'
    as plattform;
import 'privatcoach_dienst.dart';

/// Public key of the push server (not secret; the private one lives only
/// on the server).
const pushSchluessel =
    'BJ_bnfXk0Dqg_o4oevod2s5NE0dNmj-VSQDRdLqRpoUZdQ7TLW5KlS89Rm1LPMRI3PLaHZ8CK7FgrHx0QAY6KJc';

/// Where notifications stand on this device.
enum PushStand {
  /// Not possible here (yet): the phone app without Firebase.
  aus,

  /// iPhone in Safari: works only from the home screen.
  homescreen,

  /// Can be switched on with one tap.
  frage,
  erlaubt,
  blockiert,
}

/// Notifications for the chat (vault Umsetzung/Privatcoach).
class ChatPush {
  const ChatPush();

  PushStand stand() => _als(plattform.pushStatus());

  /// Like [stand], but also asks the phone (Android) without a dialog.
  Future<PushStand> pruefen() async => _als(await plattform.pushPruefen());

  static PushStand _als(String s) =>
      PushStand.values.asNameMap()[s] ?? PushStand.aus;

  /// The chat a tapped notification opened the app with ("1" = own chat).
  Future<String?> geoeffnet() => plattform.pushGeoeffnet();

  /// Called when a notification is tapped while the app runs.
  void beiTippen(void Function(String chat) wenn) =>
      plattform.pushBeiTippen(wenn);

  /// Asks for permission and saves the subscription on the server.
  Future<bool> an(PrivatcoachDienst dienst) async {
    final roh = await plattform.pushAn(pushSchluessel);
    if (roh == null) return false;
    final j = jsonDecode(roh) as Map<String, dynamic>;
    final keys = (j['keys'] as Map?)?.cast<String, dynamic>() ?? const {};
    final endpoint = j['endpoint'] as String?;
    if (endpoint == null || keys['p256dh'] == null || keys['auth'] == null) {
      return false;
    }
    await dienst.pushSpeichern(
      endpoint,
      keys['p256dh'] as String,
      keys['auth'] as String,
    );
    return true;
  }
}
