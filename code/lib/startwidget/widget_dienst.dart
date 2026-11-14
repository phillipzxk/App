import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Hands the widgets on the phone their data and brings back what was
/// tapped there (vault Umsetzung/Widgets.md). Only the phone build has
/// widgets; in the browser preview nothing happens.
abstract class WidgetDienst {
  /// Writes [daten] (see `widgetDaten`) and lets the widgets redraw.
  Future<void> senden(Map<String, Object?> daten);

  /// Day keys on which "Heute geschafft" was tapped in the widget and the
  /// app has not taken over yet.
  Future<List<String>> geschafftOffen();

  /// The app has taken them over.
  Future<void> geschafftErledigt();

  /// Where a tap on a widget wants to go ("training", "ernaehrung",
  /// "schlaf", "tag", "fokus", "heute"), until [erledigt].
  ValueListenable<String?> get getippt;

  void erledigt();
}

/// No widgets (browser, desktop, tests).
class KeinWidget implements WidgetDienst {
  @override
  final ValueNotifier<String?> getippt = ValueNotifier(null);

  @override
  Future<void> senden(Map<String, Object?> daten) async {}

  @override
  Future<List<String>> geschafftOffen() async => const [];

  @override
  Future<void> geschafftErledigt() async {}

  @override
  void erledigt() => getippt.value = null;
}

/// The same names as in ios/GroundsetWidget and the Android widgets.
abstract final class WidgetNamen {
  static const gruppe = 'group.de.phillipzxk.coachApp';
  static const daten = 'groundset_widget';
  static const offen = 'groundset_fokus_offen';

  /// The kinds of widgets on the iPhone.
  static const ios = [
    'GroundsetJetzt',
    'GroundsetFokus',
    'GroundsetTag',
    'GroundsetZeile',
    'GroundsetHeuteRund',
    'GroundsetSerieRund',
    'GroundsetJetztBreit',
  ];

  /// The widget classes on Android.
  static const android = ['JetztWidget', 'FokusWidget', 'TagWidget'];
}

/// iPhone and Android, through the home_widget package.
class HandyWidget implements WidgetDienst {
  HandyWidget() {
    unawaited(_start());
  }

  @override
  final ValueNotifier<String?> getippt = ValueNotifier(null);

  String? _zuletzt;
  late final Future<void> _bereit = _gruppe();

  Future<void> _gruppe() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await HomeWidget.setAppGroupId(WidgetNamen.gruppe);
    }
  }

  Future<void> _start() async {
    try {
      await _bereit;
      _tipp(await HomeWidget.initiallyLaunchedFromHomeWidget());
      HomeWidget.widgetClicked.listen(_tipp);
    } catch (_) {
      // Without the widget part of the system the app simply has none.
    }
  }

  void _tipp(Uri? u) {
    final z = u?.queryParameters['ziel'];
    if (z != null && z.isNotEmpty) getippt.value = z;
  }

  @override
  void erledigt() => getippt.value = null;

  @override
  Future<void> senden(Map<String, Object?> daten) async {
    final text = jsonEncode(daten);
    if (text == _zuletzt) return;
    try {
      await _bereit;
      await HomeWidget.saveWidgetData<String>(WidgetNamen.daten, text);
      _zuletzt = text;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (final n in WidgetNamen.ios) {
          await HomeWidget.updateWidget(iOSName: n);
        }
      } else {
        for (final n in WidgetNamen.android) {
          await HomeWidget.updateWidget(androidName: n);
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<String>> geschafftOffen() async {
    try {
      await _bereit;
      final t = await HomeWidget.getWidgetData<String>(WidgetNamen.offen);
      return [
        for (final k in (t ?? '').split(','))
          if (k.trim().isNotEmpty) k.trim(),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> geschafftErledigt() async {
    try {
      await _bereit;
      await HomeWidget.saveWidgetData<String>(WidgetNamen.offen, '');
      // The widget's own copy is replaced with the next [senden].
      _zuletzt = null;
    } catch (_) {}
  }
}

WidgetDienst widgetFuerPlattform() {
  if (kIsWeb) return KeinWidget();
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => HandyWidget(),
    _ => KeinWidget(),
  };
}
