import 'dart:async';
import 'dart:convert';

import 'package:alarm_kit/alarm_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'erinnerung_plan.dart';

/// A tap on a reminder: where to go ([ziel]), extra data and which button
/// was pressed (null for a tap on the reminder itself).
class Antippen {
  const Antippen(this.ziel, this.daten, this.knopf);

  final String ziel;
  final String daten;
  final String? knopf;

  static Antippen? aus(String? payload, String? knopf) {
    if (payload == null || payload.isEmpty) return null;
    final i = payload.indexOf('|');
    return i < 0
        ? Antippen(payload, '', knopf)
        : Antippen(payload.substring(0, i), payload.substring(i + 1), knopf);
  }
}

/// Puts the planned reminders on the phone. Only the phone build really
/// shows them; in the browser preview nothing happens.
abstract class ErinnerungDienst {
  /// Replaces everything planned before with [liste].
  Future<void> planen(List<Erinnerung> liste);

  /// Asks for permission once (the system asks only the first time).
  Future<void> erlaubnisFragen();

  /// Taps waiting to be handled (also the one that opened the app).
  ValueListenable<Antippen?> get getippt;

  void erledigt();

  Future<ErinnerungEinstellungen> ladeEinstellungen();
  Future<void> speichereEinstellungen(ErinnerungEinstellungen e);

  /// Sets the real alarm (iOS 26, AlarmKit) for [zeit]; null removes it.
  /// False where there is no real alarm: then the alarm stays a reminder.
  Future<bool> weckerStellen(
    DateTime? zeit, {
    required bool schlummern,
    String? ton,
  });

  /// Since when the alarm's task is waiting ("Aufstehen" was tapped), or
  /// null. Older than 45 minutes counts as done.
  Future<DateTime?> weckerAufgabeOffen();

  /// The task is done: no second ringing.
  Future<void> weckerAufgabeErledigt();

  /// Android: since when the alarm rings with its own screen open (the
  /// iPhone shows Apple's own). Null when nothing rings.
  ValueListenable<DateTime?> get klingelt;

  /// Changes when the alarm was answered, so the task is checked again.
  Listenable get weckerGeaendert;

  /// The ringing screen's buttons: "Aufstehen" or "5 Min".
  Future<void> weckerAntworten({required bool aufstehen});

  /// Android: whether the alarm still needs to be allowed once (exact
  /// time), so the app can ask first in its own words.
  Future<bool> weckerErlaubnisFehlt();

  /// Opens Android's own question for the alarm.
  Future<void> weckerErlauben();
}

/// Ids of the Android alarm (vault Umsetzung/Android nachziehen.md); the
/// other reminders use the numbers below.
abstract final class AndroidWecker {
  static const wecker = 9001;
  static const nochmal = 9002;
  static const nachklingeln = 9003;
  static const payload = 'wecker|klingeln';
  static const aufstehen = 'aufstehen';
  static const schlummern = 'schlummern';

  static const _kanal = MethodChannel('groundset/wecker');

  /// Over the lock screen only while the alarm rings or its task waits.
  static Future<void> ueberSperre(bool an) async {
    try {
      await _kanal.invokeMethod<void>('sperre', an);
    } catch (_) {}
  }

  static AndroidNotificationDetails klingeln({
    required bool mitSchlummern,
    String knopf = 'Aufstehen',
  }) => AndroidNotificationDetails(
    'groundset_wecker_echt',
    'Wecker',
    channelDescription: 'Dein Wecker am Morgen, auch bei gesperrtem Handy',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    sound: const UriAndroidNotificationSound(
      'content://settings/system/alarm_alert',
    ),
    // FLAG_INSISTENT: rings until it is answered.
    additionalFlags: Int32List.fromList(const [4]),
    ongoing: true,
    autoCancel: false,
    visibility: NotificationVisibility.public,
    color: const Color(0xFFE0BF7E),
    actions: [
      if (mitSchlummern) const AndroidNotificationAction(schlummern, '5 Min'),
      AndroidNotificationAction(aufstehen, knopf, showsUserInterface: true),
    ],
  );

  /// Rings once more in [in_], with only the one button.
  static Future<void> nochmalIn(
    FlutterLocalNotificationsPlugin plugin,
    Duration in_, {
    int id = nochmal,
    String titel = 'Guten Morgen',
    String knopf = 'Aufstehen',
  }) => plugin.zonedSchedule(
    id: id,
    scheduledDate: tz.TZDateTime.from(DateTime.now().add(in_), tz.UTC),
    title: titel,
    body: null,
    payload: payload,
    androidScheduleMode: AndroidScheduleMode.alarmClock,
    notificationDetails: NotificationDetails(
      android: klingeln(mitSchlummern: false, knopf: knopf),
    ),
  );
}

/// "5 Min" on the ringing alarm when the app is closed: rings once more in
/// 5 minutes, then only with "Aufstehen" (as on the iPhone).
@pragma('vm:entry-point')
Future<void> weckerImHintergrund(NotificationResponse r) async {
  if (r.actionId != AndroidWecker.schlummern) return;
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancel(id: AndroidWecker.nochmal);
    await AndroidWecker.nochmalIn(plugin, const Duration(minutes: 5));
  } catch (_) {}
}

/// Written by the alarm's buttons in Swift (AppDelegate.swift).
const weckerAufgabeKey = 'wecker_aufgabe_seit';

/// The same ids as in AppDelegate.swift.
abstract final class WeckerIds {
  static const wecker = '0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A01';
  static const schlummern = '0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A02';
  static const nachklingeln = '0E1D5A3C-6B2F-4C7E-9A11-6F3B2D8C4A03';
}

DateTime? _offenSeit(String? roh, DateTime jetzt) {
  final t = roh == null ? null : DateTime.tryParse(roh)?.toLocal();
  if (t == null || jetzt.difference(t).inMinutes > 45) return null;
  return t;
}

const _einstellungenKey = 'erinnerungen_einstellungen';

/// For the browser preview and tests: plans nothing, keeps the settings.
class StilleErinnerungen implements ErinnerungDienst {
  StilleErinnerungen();

  List<Erinnerung> geplant = const [];
  bool gefragt = false;
  ErinnerungEinstellungen _e = const ErinnerungEinstellungen();
  final _getippt = ValueNotifier<Antippen?>(null);

  @override
  Future<void> planen(List<Erinnerung> liste) async => geplant = liste;

  @override
  Future<void> erlaubnisFragen() async => gefragt = true;

  @override
  ValueListenable<Antippen?> get getippt => _getippt;

  /// For tests: as if the user tapped a reminder.
  void tippen(Antippen a) => _getippt.value = a;

  @override
  void erledigt() => _getippt.value = null;

  @override
  Future<ErinnerungEinstellungen> ladeEinstellungen() async => _e;

  @override
  Future<void> speichereEinstellungen(ErinnerungEinstellungen e) async =>
      _e = e;

  /// For tests: where the alarm was set, and the waiting task.
  DateTime? wecker;
  String? weckerTon;
  DateTime? aufgabeSeit;

  @override
  Future<bool> weckerStellen(
    DateTime? zeit, {
    required bool schlummern,
    String? ton,
  }) async {
    wecker = zeit;
    weckerTon = ton;
    return false;
  }

  @override
  Future<DateTime?> weckerAufgabeOffen() async => aufgabeSeit;

  @override
  Future<void> weckerAufgabeErledigt() async => aufgabeSeit = null;

  final _klingelt = ValueNotifier<DateTime?>(null);
  final _geaendert = ValueNotifier<int>(0);

  /// For tests: as if the Android alarm rings now.
  void klingeln(DateTime seit) => _klingelt.value = seit;

  @override
  ValueListenable<DateTime?> get klingelt => _klingelt;

  @override
  Listenable get weckerGeaendert => _geaendert;

  @override
  Future<void> weckerAntworten({required bool aufstehen}) async {
    _klingelt.value = null;
    if (aufstehen) aufgabeSeit = DateTime.now();
    _geaendert.value++;
  }

  bool erlaubnisFehlt = false;

  @override
  Future<bool> weckerErlaubnisFehlt() async => erlaubnisFehlt;

  @override
  Future<void> weckerErlauben() async => erlaubnisFehlt = false;
}

/// The real reminders on iPhone and Android.
class HandyErinnerungen implements ErinnerungDienst {
  HandyErinnerungen();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _getippt = ValueNotifier<Antippen?>(null);
  Future<void>? _start;

  static const _kanal = AndroidNotificationDetails(
    'groundset',
    'Erinnerungen',
    channelDescription: 'Check-in, Training, Supplements, Abendroutine',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _weckerKanal = AndroidNotificationDetails(
    'groundset_wecker',
    'Wecker',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
  );

  static final _kategorien = [
    DarwinNotificationCategory(
      'supplements',
      actions: [
        DarwinNotificationAction.plain(
          Knopf.abhaken,
          'Abhaken',
          options: {DarwinNotificationActionOption.foreground},
        ),
      ],
    ),
    DarwinNotificationCategory(
      'fokus',
      actions: [
        DarwinNotificationAction.plain(
          Knopf.geschafft,
          'Geschafft',
          options: {DarwinNotificationActionOption.foreground},
        ),
        DarwinNotificationAction.plain(Knopf.heuteNicht, 'Heute nicht'),
      ],
    ),
  ];

  Future<void> _starten() => _start ??= () async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    }
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: _kategorien,
        ),
      ),
      onDidReceiveNotificationResponse: _antwort,
      onDidReceiveBackgroundNotificationResponse: weckerImHintergrund,
    );
    final start = await _plugin.getNotificationAppLaunchDetails();
    final r = start?.notificationResponse;
    if (start?.didNotificationLaunchApp == true && r != null) _antwort(r);
  }();

  void _antwort(NotificationResponse r) {
    if (r.payload?.startsWith('wecker|') == true) {
      unawaited(_weckerGetippt(r.actionId));
      return;
    }
    _getippt.value = Antippen.aus(r.payload, r.actionId);
  }

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  final _klingelt = ValueNotifier<DateTime?>(null);
  final _geaendert = ValueNotifier<int>(0);

  @override
  ValueListenable<DateTime?> get klingelt {
    // Started here too: the alarm can open the app before Heute exists.
    unawaited(_starten());
    return _klingelt;
  }

  @override
  Listenable get weckerGeaendert => _geaendert;

  /// The Android alarm: opened by itself (full screen over the lock
  /// screen) or a tap shows the ringing screen; a button answers it.
  Future<void> _weckerGetippt(String? knopf) async {
    switch (knopf) {
      case AndroidWecker.aufstehen:
        await weckerAntworten(aufstehen: true);
      case AndroidWecker.schlummern:
        await weckerAntworten(aufstehen: false);
      default:
        _klingelt.value = DateTime.now();
    }
  }

  @override
  Future<void> weckerAntworten({required bool aufstehen}) async {
    await _starten();
    for (final id in [AndroidWecker.wecker, AndroidWecker.nochmal]) {
      await _plugin.cancel(id: id);
    }
    if (aufstehen) {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        weckerAufgabeKey,
        DateTime.now().toUtc().toIso8601String(),
      );
      // If the task is not done within 3 minutes, it rings once more.
      await AndroidWecker.nochmalIn(
        _plugin,
        const Duration(minutes: 3),
        id: AndroidWecker.nachklingeln,
        titel: 'Deine Aufgabe wartet',
        knopf: 'Aufgabe machen',
      );
    } else {
      await AndroidWecker.nochmalIn(_plugin, const Duration(minutes: 5));
      await AndroidWecker.ueberSperre(false);
    }
    _klingelt.value = null;
    _geaendert.value++;
  }

  @override
  Future<bool> weckerErlaubnisFehlt() async {
    if (!_android) return false;
    await _starten();
    try {
      return !(await _androidPlugin?.canScheduleExactNotifications() ?? true);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> weckerErlauben() async {
    await _starten();
    final a = _androidPlugin;
    await a?.requestExactAlarmsPermission();
    await a?.requestFullScreenIntentPermission();
    _geaendert.value++;
  }

  @override
  ValueListenable<Antippen?> get getippt {
    unawaited(_starten());
    return _getippt;
  }

  @override
  void erledigt() => _getippt.value = null;

  @override
  Future<void> erlaubnisFragen() async {
    await _starten();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
  }

  @override
  Future<void> planen(List<Erinnerung> liste) async {
    await _starten();
    // The Android alarm (ids from 9000) stays; it is set by weckerStellen.
    for (final alt in await _plugin.pendingNotificationRequests()) {
      if (alt.id < 9000) await _plugin.cancel(id: alt.id);
    }
    // Without the exact-time permission Android still reminds, a little
    // later at most.
    final genau = !_android || !await weckerErlaubnisFehlt();
    // iOS keeps at most 64 planned reminders.
    var id = 0;
    for (final e in liste.take(60)) {
      final wecker = e.art == ErinnerungArt.wecker;
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: tz.TZDateTime.from(e.zeit, tz.local),
        title: e.titel,
        body: e.text,
        payload: e.payload,
        androidScheduleMode: genau
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        notificationDetails: NotificationDetails(
          android: wecker ? _weckerKanal : _kanal,
          iOS: DarwinNotificationDetails(
            presentSound: true,
            threadIdentifier: 'groundset',
            categoryIdentifier: switch (e.art) {
              ErinnerungArt.supplements => 'supplements',
              ErinnerungArt.fokus => 'fokus',
              _ => null,
            },
            interruptionLevel: wecker
                ? InterruptionLevel.timeSensitive
                : InterruptionLevel.active,
          ),
        ),
      );
    }
  }

  @override
  Future<ErinnerungEinstellungen> ladeEinstellungen() async {
    final p = await SharedPreferences.getInstance();
    final roh = p.getString(_einstellungenKey);
    if (roh == null) return const ErinnerungEinstellungen();
    return ErinnerungEinstellungen.fromJson(
      jsonDecode(roh) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> speichereEinstellungen(ErinnerungEinstellungen e) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_einstellungenKey, jsonEncode(e.toJson()));
  }

  static const _gold = Color(0xFFE0BF7E);
  final _kit = AlarmKit.instance;

  Future<bool> _weckerDa() async {
    try {
      if (!await _kit.isSupported()) return false;
      var a = await _kit.authorizationState();
      if (a == AlarmAuthorization.notDetermined) {
        a = await _kit.requestAuthorization();
      }
      return a == AlarmAuthorization.authorized;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> weckerStellen(
    DateTime? zeit, {
    required bool schlummern,
    String? ton,
  }) async {
    if (_android) return _androidWeckerStellen(zeit, schlummern: schlummern);
    if (!await _weckerDa()) return false;
    try {
      // The ringing after "5 Min" and after an undone task is set in Swift
      // (AppDelegate.swift) and reads the sound from here.
      final p = await SharedPreferences.getInstance();
      if (ton == null) {
        await p.remove('wecker_ton');
      } else {
        await p.setString('wecker_ton', ton);
      }
      if (zeit == null) {
        for (final id in [WeckerIds.wecker, WeckerIds.schlummern]) {
          try {
            await _kit.cancel(id);
          } catch (_) {}
        }
        return true;
      }
      // Rings at the wake-up time; "5 Min" rings once more (in Swift),
      // "Aufstehen" opens the task.
      await _kit.scheduleAlarm(
        id: WeckerIds.wecker,
        schedule: AlarmSchedule.fixed(zeit),
        tint: _gold,
        metadataKind: 'wecker',
        sound: ton,
        stopIntent: 'aufstehen',
        secondaryIntent: schlummern ? 'schlummern' : null,
        presentation: AlarmPresentation(
          alert: AlarmAlert(
            title: 'Guten Morgen',
            stopButton: const AlarmButton(
              text: 'Aufstehen',
              systemImageName: 'sun.max.fill',
            ),
            secondaryButton: schlummern
                ? const AlarmButton(
                    text: '5 Min',
                    systemImageName: 'moon.zzz.fill',
                  )
                : null,
            secondaryBehavior: schlummern
                ? AlarmSecondaryBehavior.custom
                : null,
          ),
        ),
      );
      // In case nothing is tapped: rings once more after 10 minutes.
      await _kit.scheduleAlarm(
        id: WeckerIds.schlummern,
        schedule: AlarmSchedule.fixed(zeit.add(const Duration(minutes: 10))),
        tint: _gold,
        metadataKind: 'wecker',
        sound: ton,
        stopIntent: 'aufstehen',
        presentation: const AlarmPresentation(
          alert: AlarmAlert(
            title: 'Guten Morgen',
            stopButton: AlarmButton(
              text: 'Aufstehen',
              systemImageName: 'sun.max.fill',
            ),
          ),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Android: a real alarm over the notifications (full screen, alarm
  /// sound, rings until answered). The sounds chosen for the iPhone are
  /// not on Android; it uses the phone's own alarm sound.
  Future<bool> _androidWeckerStellen(
    DateTime? zeit, {
    required bool schlummern,
  }) async {
    await _starten();
    if (await weckerErlaubnisFehlt()) return false;
    try {
      for (final id in [AndroidWecker.wecker, AndroidWecker.nochmal]) {
        await _plugin.cancel(id: id);
      }
      if (zeit == null || !zeit.isAfter(DateTime.now())) return true;
      Future<void> stellen(int id, DateTime wann, bool mitSchlummern) =>
          _plugin.zonedSchedule(
            id: id,
            scheduledDate: tz.TZDateTime.from(wann, tz.local),
            title: 'Guten Morgen',
            body: 'Zeit aufzustehen. Erst raus, dann Licht.',
            payload: AndroidWecker.payload,
            androidScheduleMode: AndroidScheduleMode.alarmClock,
            notificationDetails: NotificationDetails(
              android: AndroidWecker.klingeln(mitSchlummern: mitSchlummern),
            ),
          );
      await stellen(AndroidWecker.wecker, zeit, schlummern);
      // In case nothing is tapped: rings once more after 10 minutes.
      await stellen(
        AndroidWecker.nochmal,
        zeit.add(const Duration(minutes: 10)),
        false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<DateTime?> weckerAufgabeOffen() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return _offenSeit(p.getString(weckerAufgabeKey), DateTime.now());
  }

  @override
  Future<void> weckerAufgabeErledigt() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(weckerAufgabeKey);
    if (_android) {
      try {
        await _plugin.cancel(id: AndroidWecker.nachklingeln);
      } catch (_) {}
      await AndroidWecker.ueberSperre(false);
      return;
    }
    try {
      if (await _kit.isSupported()) await _kit.cancel(WeckerIds.nachklingeln);
    } catch (_) {}
  }
}

/// The right one for where the app runs.
ErinnerungDienst erinnerungenFuerPlattform() {
  if (kIsWeb) return _WebErinnerungen();
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => HandyErinnerungen(),
    _ => StilleErinnerungen(),
  };
}

/// Browser preview: nothing is shown, but the settings are kept.
class _WebErinnerungen extends StilleErinnerungen {
  @override
  Future<ErinnerungEinstellungen> ladeEinstellungen() async {
    final p = await SharedPreferences.getInstance();
    final roh = p.getString(_einstellungenKey);
    if (roh == null) return const ErinnerungEinstellungen();
    return ErinnerungEinstellungen.fromJson(
      jsonDecode(roh) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> speichereEinstellungen(ErinnerungEinstellungen e) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_einstellungenKey, jsonEncode(e.toJson()));
  }
}
