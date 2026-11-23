// Phone apps. Android: Firebase Cloud Messaging (vault Umsetzung/Privatcoach).
// The iPhone app has no push yet (needs the Apple developer account).
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../plattform/plattform.dart';

bool get _android =>
    istAndroid && !Platform.environment.containsKey('FLUTTER_TEST');

String pushStatus() => _android ? (_erlaubt ? 'erlaubt' : 'frage') : 'aus';

bool _erlaubt = false;
bool _bereit = false;

Future<FirebaseMessaging> _fcm() async {
  if (!_bereit) {
    await Firebase.initializeApp();
    _bereit = true;
  }
  return FirebaseMessaging.instance;
}

/// Asks once whether it is already allowed (no dialog).
Future<String> pushPruefen() async {
  if (!_android) return 'aus';
  try {
    final s = await (await _fcm()).getNotificationSettings();
    _erlaubt = s.authorizationStatus == AuthorizationStatus.authorized;
    if (s.authorizationStatus == AuthorizationStatus.denied) return 'blockiert';
  } catch (_) {}
  return pushStatus();
}

/// Same shape as the browser's subscription: {endpoint, keys}.
Future<String?> pushAn(String schluessel) async {
  if (!_android) return null;
  try {
    final m = await _fcm();
    final s = await m.requestPermission();
    if (s.authorizationStatus != AuthorizationStatus.authorized) return null;
    _erlaubt = true;
    // Registration tokens work with the FCM HTTP v1 API the server uses.
    // ignore: deprecated_member_use
    final token = await m.getToken();
    if (token == null) return null;
    return '{"endpoint":"fcm:$token","keys":{"p256dh":"fcm","auth":"fcm"}}';
  } catch (_) {
    return null;
  }
}

/// Where a tapped notification wants to go ("1" or a chat id), once.
Future<String?> pushGeoeffnet() async {
  if (!_android) return null;
  try {
    final m = await _fcm();
    final r = await m.getInitialMessage();
    return r?.data['chat'] as String?;
  } catch (_) {
    return null;
  }
}

/// Taps while the app runs in the background.
void pushBeiTippen(void Function(String chat) wenn) {
  if (!_android) return;
  _fcm()
      .then((_) {
        FirebaseMessaging.onMessageOpenedApp.listen((r) {
          final c = r.data['chat'];
          if (c is String) wenn(c);
        });
      })
      .catchError((_) {});
}
