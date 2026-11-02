import 'package:coach_app/abo/abo_ablauf.dart';
import 'package:coach_app/abo/abo_daten.dart';
import 'package:coach_app/abo/abo_logik.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/checkin/checkin_evaluator.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/durchgezogen.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _Antwort implements CheckInEvaluator {
  @override
  Future<String?> reply(UserProfile p, CheckIn t, List<CheckIn> r) async =>
      'Gut gemacht.';

  @override
  Future<Map<String, BereichsWert>?> rate(
    UserProfile p,
    CheckIn t,
    List<CheckIn> r,
  ) async => null;
}

class _Woche implements WochenCoach {
  List<CheckIn>? bekommen;

  @override
  Future<String?> wochenRueckblick(
    UserProfile profile,
    List<CheckIn> woche, {
    String muster = '',
    bool erste = false,
  }) async {
    bekommen = woche;
    return 'Deine Woche in einem Satz.';
  }
}

void main() {
  // Monday 12 Oct 2026.
  final montag = DateTime(2026, 10, 12, 18);
  AboStand seit(int tage) =>
      AboStand(gratisSeit: DateTime(2026, 10, 12 - tage));

  group('Gratis-Woche', () {
    test('Tag zählt ab dem ersten Tag', () {
      expect(seit(0).gratisTag(montag), 1);
      expect(seit(5).zaehlerTag(montag), 6);
      expect(seit(7).zaehlerTag(montag), isNull);
      expect(const AboStand().zaehlerTag(montag), isNull);
    });

    test('Abo-Bildschirm ab Tag 7, bis entschieden', () {
      expect(seit(5).zeigeAbo(montag), isFalse);
      expect(seit(6).zeigeAbo(montag), isTrue);
      expect(seit(9).zeigeAbo(montag), isTrue);
      expect(seit(6).ohne().zeigeAbo(montag), isFalse);
      expect(seit(6).mitPlan(AboPlan.jahr, montag).zeigeAbo(montag), isFalse);
    });

    test('Coach an in der Gratis-Woche und mit Abo, sonst still', () {
      expect(seit(6).coachAn(montag), isTrue);
      expect(seit(8).ohne().coachAn(montag), isFalse);
      expect(seit(8).mitPlan(AboPlan.monat, montag).coachAn(montag), isTrue);
      final sonntag = DateTime(2026, 10, 18, 9);
      expect(seit(8).ohne().wochenSatzTag(sonntag), isTrue);
      expect(seit(8).ohne().wochenSatzTag(montag), isFalse);
    });

    test('ohne Abo bleiben nur Werte, Muster und Wochen-Satz', () {
      final ohne = seit(8).ohne();
      expect(pfadErlaubt('/checkin', ohne, montag), isFalse);
      expect(pfadErlaubt('/ernaehrung', ohne, montag), isFalse);
      expect(pfadErlaubt('/werte', ohne, montag), isTrue);
      expect(pfadErlaubt('/muster', ohne, montag), isTrue);
      expect(pfadErlaubt('/woche', ohne, montag), isTrue);
      expect(pfadErlaubt('/checkin', seit(2), montag), isTrue);
    });

    test('nächste Zahlung', () {
      final s = const AboStand().mitPlan(AboPlan.jahr, DateTime(2026, 11, 16));
      expect(s.naechsteZahlung(DateTime(2026, 11, 20)), DateTime(2027, 11, 16));
      final m = const AboStand().mitPlan(AboPlan.monat, DateTime(2026, 11, 16));
      expect(m.naechsteZahlung(DateTime(2026, 11, 20)), DateTime(2026, 12, 16));
    });

    test('gespeichert und wieder geladen', () {
      final s = seit(3).mitPlan(AboPlan.jahr, montag);
      final z = AboStand.fromJson(s.toJson());
      expect(z.plan, AboPlan.jahr);
      expect(z.gratisSeit, s.gratisSeit);
      expect(AboStand.fromJson(seit(3).ohne().toJson()).ohneAbo, isTrue);
    });
  });

  group('Coach-Antwort', () {
    final heute = checkInOn(montag);
    final p = const UserProfile(name: 'Phillip');

    test('Tag 6 kündigt die Woche an', () async {
      final e = AboEvaluator(
        inner: _Antwort(),
        stand: () => seit(5),
        clock: () => montag,
      );
      expect(await e.reply(p, heute, []), 'Gut gemacht. $tag6Satz');
    });

    test('ohne Abo unter der Woche still, sonntags der Wochen-Satz', () async {
      final w = _Woche();
      var jetzt = montag;
      final e = AboEvaluator(
        inner: _Antwort(),
        stand: () => seit(10).ohne(),
        clock: () => jetzt,
        woche: w,
      );
      expect(await e.reply(p, heute, []), stillSatz);
      jetzt = DateTime(2026, 10, 18, 9);
      final so = checkInOn(jetzt);
      expect(await e.reply(p, so, [heute]), 'Deine Woche in einem Satz.');
      expect(w.bekommen!.length, 2);
    });
  });

  test('Wochenbild zählt die 7 Tage', () {
    final tage = [
      for (var i = 0; i < 7; i++)
        if (i != 3) DateTime(2026, 10, 6 + i),
    ];
    final b = WochenBild.aus(
      jetzt: montag,
      checkIns: [for (final t in tage) checkInOn(t, training: 'Gut trainiert')],
      fokus: Wochenfokus(
        start: DateTime(2026, 10, 6),
        text: 'Früh ins Bett',
        geschafft: {'2026-10-06', '2026-10-07', '2026-09-01'},
      ),
      durch: [
        Durchgezogen(
          datum: DateTime(2026, 10, 8),
          text: 'Gelaufen',
          vonCoach: false,
          erstellt: DateTime(2026, 10, 8),
        ),
      ],
      muster: [
        Muster(
          datum: DateTime(2026, 10, 10),
          text: 'Kurze Nacht, dann Heißhunger',
          schritt: '',
          von: '',
          nach: '',
        ),
      ],
    );
    expect(b.checkIns, 6);
    expect(b.punkte.map((p) => p.tag).toList(), [
      'Di',
      'Mi',
      'Do',
      'Fr',
      'Sa',
      'So',
      'Mo',
    ]);
    expect(b.punkte[3].text, 'kein Check-in');
    expect(b.fokusTage, 2);
    expect(b.durchgezogen, 1);
    expect(b.muster, 'Kurze Nacht, dann Heißhunger');
  });

  testWidgets('Abo-Bildschirm: Jahr kaufen, dann Danke', (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AboStand? gespeichert;
    var fertig = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AboAblauf(
          name: 'Phillip',
          laden: () async => WochenBild.aus(jetzt: montag, checkIns: []),
          text: (_) async => 'Sechsmal hast du hingeschaut.',
          kauf: const VorschauKauf(),
          stand: seit(6),
          onStand: (s) async => gespeichert = s,
          onFertig: () => fertig = true,
          clock: () => montag,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('59,99 €'), findsOneWidget);
    expect(find.text('9,99 €'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('abo-plan-monat')));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('9,99 € im Monat.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('abo-plan-jahr')));
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(find.byKey(const ValueKey('abo-kaufen')));
    await tester.tap(find.byKey(const ValueKey('abo-kaufen')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));
    expect(gespeichert?.plan, AboPlan.jahr);
    expect(find.text('Phillip, wir wachsen weiter.'), findsOneWidget);
    expect(find.textContaining('Abo aktiv · Jahr'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('abo-zu-heute')));
    await tester.tap(find.byKey(const ValueKey('abo-zu-heute')));
    expect(fertig, isTrue);
  });

  testWidgets(
    'App: an Tag 7 kommt nach dem Check-in der Abo-Bildschirm, ohne Abo dann grauer Coach',
    (tester) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final abo = MemoryAboStore(seit(6));
      final diary = MemoryDiaryStore()
        ..checkIns.add(checkInOn(fixedNow, reply: 'Weiter so.'));
      await tester.pumpWidget(
        CoachApp(
          store: MemoryProfileStore(
            const UserProfile(name: 'Phillip', ziel: 'Frei sein'),
          ),
          diary: diary,
          feed: MemoryFeedStore(),
          clock: fixedClock,
          aboStore: abo,
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(const ValueKey('abo-seite')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('abo-ohne')));
      await tester.tap(find.byKey(const ValueKey('abo-ohne')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(abo.stand.ohneAbo, isTrue);
      expect(find.byKey(const ValueKey('coach-still')), findsOneWidget);
      expect(find.byKey(const ValueKey('coach-einschalten')), findsOneWidget);
    },
  );

  testWidgets('App: Zähler in der Gratis-Woche, Tag 6 mit Morgen-Karte', (
    tester,
  ) async {
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow, reply: 'Weiter so.'));
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(
          const UserProfile(name: 'Phillip', ziel: 'Frei sein'),
        ),
        diary: diary,
        feed: MemoryFeedStore(),
        clock: fixedClock,
        aboStore: MemoryAboStore(seit(5)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('abo-zaehler')), findsOneWidget);
    expect(find.textContaining('6 von 7', findRichText: true), findsOneWidget);
    expect(find.byKey(const ValueKey('abo-morgen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('abo-zaehler')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('abo-blase')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
