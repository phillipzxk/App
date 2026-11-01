import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      onDidReceiveNotificationResponse: (r) =>
          _getippt.value = Antippen.aus(r.payload, r.actionId),
    );
    final start = await _plugin.getNotificationAppLaunchDetails();
    final r = start?.notificationResponse;
    if (start?.didNotificationLaunchApp == true && r != null) {
      _getippt.value = Antippen.aus(r.payload, r.actionId);
    }
  }();

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
    await android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> planen(List<Erinnerung> liste) async {
    await _starten();
    await _plugin.cancelAllPendingNotifications();
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
