import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/kalender/kalender_dienst.dart';
import 'package:coach_app/kalender/kalender_logik.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/planner/planner_data.dart';
import 'package:coach_app/schnell/schnell_eintrag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(ziel: 'Frei sein', motivation: 'Stolz sein.');

/// A phone calendar in memory: "Privat" (default) and "Arbeit".
class _Kalender implements KalenderDienst {
  _Kalender({this.erlaubt = true});
  final bool erlaubt;
  final angelegt = <(Termin, String?)>[];
  final eigene = <(String, Termin)>[
    (
      'arbeit',
      Termin(
        datum: fixedNow,
        zeit: '13:00',
        text: 'Call mit Paul',
        erstellt: fixedNow,
        kalender: 'Arbeit',
      ),
    ),
  ];

  @override
  bool get moeglich => true;
  @override
  String get name => 'iPhone-Kalender';
  @override
  Future<bool> verbinden() async => erlaubt;
  @override
  Future<List<KalenderInfo>> kalender() async => const [
    KalenderInfo(id: 'privat', name: 'Privat'),
    KalenderInfo(id: 'arbeit', name: 'Arbeit'),
  ];
  @override
  Future<List<Termin>> termine(DateTime v, DateTime b, Set<String> aus) async =>
      [
        for (final (k, t) in eigene)
          if (!aus.contains(k)) t,
      ];
  @override
  Future<bool> anlegen(Termin t, String? k) async {
    angelegt.add((t, k));
    eigene.add((
      k ?? 'privat',
      Termin(
        datum: t.datum,
        zeit: t.zeit,
        text: t.text,
        erstellt: t.erstellt,
        kalender: k == 'arbeit' ? 'Arbeit' : 'Privat',
      ),
    ));
    return true;
  }
}

Future<void> _deinTag(
  WidgetTester tester,
  MemoryFeedStore feed,
  KalenderDienst kalender,
) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: feed,
      clock: fixedClock,
      kalender: kalender,
    ),
  );
  await tester.pumpAndSettle();
  await scrollTo(tester, find.byKey(const ValueKey('dein-tag')));
  await tester.tap(find.byKey(const ValueKey('dein-tag')));
  await tester.pumpAndSettle();
}

void main() {
  test('connecting moves the own appointments from today on', () async {
    final feed = MemoryFeedStore()
      ..termine.addAll([
        Termin(
          datum: fixedNow.subtract(const Duration(days: 1)),
          text: 'Gestern',
          erstellt: fixedNow,
        ),
        Termin(
          datum: fixedNow.add(const Duration(days: 2)),
          zeit: '17:00',
          text: 'Zahnarzt',
          erstellt: fixedNow.add(const Duration(seconds: 1)),
        ),
      ]);
    final k = _Kalender();
    expect(await kalenderVerbinden(k, feed, fixedNow), isTrue);
    expect(k.angelegt.single.$1.text, 'Zahnarzt');
    expect(feed.termine.single.text, 'Gestern');
    expect(feed.kalender.verbunden, isTrue);

    await kalenderTrennen(feed);
    expect(feed.kalender.verbunden, isFalse);
  });

  test('not allowed changes nothing', () async {
    final feed = MemoryFeedStore()
      ..termine.add(
        Termin(datum: fixedNow, text: 'Bleibt', erstellt: fixedNow),
      );
    expect(
      await kalenderVerbinden(_Kalender(erlaubt: false), feed, fixedNow),
      isFalse,
    );
    expect(feed.termine, hasLength(1));
    expect(feed.kalender.verbunden, isFalse);
  });

  test('settings survive a round trip', () {
    const e = KalenderEinstellung(verbunden: true, aus: {'a'}, ziel: 'b');
    final z = KalenderEinstellung.fromJson(e.toJson());
    expect(z.verbunden, isTrue);
    expect(z.aus, {'a'});
    expect(z.ziel, 'b');
  });

  testWidgets('one button, then the calendar fills Dein Tag', (tester) async {
    final feed = MemoryFeedStore();
    final k = _Kalender();
    await _deinTag(tester, feed, k);

    final knopf = find.byKey(const ValueKey('kalender-verbinden'));
    await tester.ensureVisible(knopf);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('termin-feld')), findsOneWidget);
    expect(find.text('Call mit Paul'), findsNothing);

    await tester.tap(knopf);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(feed.kalender.verbunden, isTrue);
    expect(find.byKey(const ValueKey('kalender-karte')), findsNothing);
    expect(find.byKey(const ValueKey('termin-feld')), findsNothing);
    expect(find.text('iPhone-Kalender verbunden'), findsOneWidget);
    expect(find.text('1 Termin heute'), findsOneWidget);
    expect(find.text('Call mit Paul'), findsWidgets);
    expect(find.text('KALENDER'), findsOneWidget);
    expect(find.byTooltip('Termin löschen'), findsNothing);
  });

  testWidgets('without a calendar on the phone the field stays alone', (
    tester,
  ) async {
    await _deinTag(tester, MemoryFeedStore(), const KeinKalender());
    expect(find.byKey(const ValueKey('kalender-verbinden')), findsNothing);
    expect(find.byKey(const ValueKey('termin-feld')), findsOneWidget);
  });

  testWidgets('Schnell-Eintrag puts an appointment into the calendar', (
    tester,
  ) async {
    final feed = MemoryFeedStore()
      ..kalender = const KalenderEinstellung(verbunden: true, ziel: 'arbeit');
    final k = _Kalender();
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow)),
        feed: feed,
        clock: fixedClock,
        kalender: k,
        feedCoach: _NurTermin(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schnell-knopf')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('schnell-feld')), 'x');
    await tester.tap(find.byKey(const ValueKey('schnell-senden')));
    await tester.pumpAndSettle();
    expect(find.text('in deinen iPhone-Kalender'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('schnell-fertig')));
    await tester.tap(find.byKey(const ValueKey('schnell-fertig')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    final (t, ziel) = k.angelegt.single;
    expect(t.text, 'Zahnarzt');
    expect(t.zeit, '10:00');
    expect(ziel, 'arbeit');
    expect(feed.termine, isEmpty);
  });
}

class _NurTermin extends NoFeedCoach implements SchnellCoach {
  @override
  Future<SchnellAntwort?> schnell(UserProfile p, String t, String k) async =>
      SchnellAntwort(
        eintraege: [
          SchnellEintrag.fromJson({
            'art': 'termin',
            'titel': 'Morgen 10:00 Zahnarzt',
            'text': 'Zahnarzt',
            'tag': 1,
            'zeit': '10:00',
          })!,
        ],
      );
}
