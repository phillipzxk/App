import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/durchgezogen.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/fokus.dart';
import 'package:coach_app/feed/muster.dart';
import 'package:coach_app/home/durchgezogen_widgets.dart';
import 'package:coach_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

class _DurchCoach implements FeedCoach {
  @override
  Future<String?> warumSatz(
    UserProfile profile,
    CheckIn today,
    List<CheckIn> recent,
  ) async => null;

  _DurchCoach(this.eintrag);

  final String? eintrag;
  int calls = 0;
  List<Durchgezogen> bisher = const [];

  @override
  Future<String?> answer(
    UserProfile profile,
    Bereich bereich,
    String text, {
    String context = '',
  }) async => null;

  @override
  Future<Muster?> findeMuster(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> bisher,
  ) async => null;

  @override
  Future<FokusAuswahl?> fokusVorschlaege(
    UserProfile profile,
    List<CheckIn> checkIns,
    List<Muster> muster, {
    Wochenfokus? letzter,
    TrainingWoche? training,
  }) async => null;

  @override
  Future<List<String>?> stichpunkte(String text) async => null;

  @override
  Future<String?> durchgezogen(
    UserProfile profile,
    CheckIn today, {
    String? fokus,
    bool fokusGeschafft = false,
    List<Durchgezogen> bisher = const [],
  }) async {
    calls++;
    this.bisher = bisher;
    return eintrag;
  }
}

DateTime _tag(int zurueck) =>
    DateTime(fixedNow.year, fixedNow.month, fixedNow.day - zurueck);

Durchgezogen _e(int zurueck, String text, {bool coach = false}) => Durchgezogen(
  datum: _tag(zurueck),
  text: text,
  vonCoach: coach,
  erstellt: _tag(zurueck).add(Duration(hours: 20, minutes: text.length)),
);

Future<(MemoryFeedStore, _DurchCoach)> _open(
  WidgetTester tester, {
  String? eintrag,
  List<Durchgezogen> vorher = const [],
  bool checkIn = true,
}) async {
  final diary = MemoryDiaryStore();
  if (checkIn) diary.checkIns.add(checkInOn(fixedNow));
  final feed = MemoryFeedStore()..durchgezogen.addAll(vorher);
  final coach = _DurchCoach(eintrag);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(const UserProfile(ziel: 'Frei sein')),
      diary: diary,
      feed: feed,
      feedCoach: coach,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return (feed, coach);
}

void main() {
  group('weeks', () {
    test('week starts on Monday', () {
      expect(wochenStart(DateTime(2026, 10, 18, 22)), DateTime(2026, 10, 12));
      expect(wochenStart(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
    });

    test('this week oldest first, all weeks newest first', () {
      final all = [
        _e(0, 'heute'),
        _e(3, 'letzte Woche'),
        _e(9, 'vorletzte'),
        _e(1, 'gestern'),
      ];
      expect(inWoche(all, fixedNow).map((e) => e.text), ['heute']);
      final w = nachWochen(all);
      expect(w.map((x) => x.$1), [
        DateTime(2026, 10, 12),
        DateTime(2026, 10, 5),
        DateTime(2026, 9, 28),
      ]);
      expect(w[1].$2.map((e) => e.text), ['gestern', 'letzte Woche']);
      expect(wochenTitel(DateTime(2026, 10, 5)), '5. BIS 11. OKT');
      expect(wochenTitel(DateTime(2026, 9, 28)), '28. SEP BIS 4. OKT');
    });

    test('json round trip', () {
      final a = _e(2, 'x', coach: true);
      final b = Durchgezogen.fromJson(a.toJson());
      expect(b.text, 'x');
      expect(b.vonCoach, isTrue);
      expect(b.datum, a.datum);
      expect(b.erstellt, a.erstellt);
    });
  });

  testWidgets('coach adds one entry after the check-in, once a day', (
    tester,
  ) async {
    final (feed, coach) = await _open(
      tester,
      eintrag: 'Trotz Unlust trainiert.',
      vorher: [_e(2, 'Handy draußen gelassen.')],
    );
    expect(coach.calls, 1);
    expect(coach.bisher.single.text, 'Handy draußen gelassen.');
    expect(feed.durchgezogen.last.vonCoach, isTrue);
    expect(feed.durchgezogen.last.datum, _tag(0));

    await openTab(tester, 'Mindset');
    await scrollTo(tester, find.byKey(const ValueKey('durch-karte')));
    expect(find.text('Trotz Unlust trainiert.'), findsOneWidget);
    expect(find.text('COACH'), findsOneWidget);
    expect(
      find.textContaining('letzte Woche 1', findRichText: true),
      findsOneWidget,
    );
    expect(feed.durchGeprueft, dayKey(fixedNow));
  });

  testWidgets('no check-in today or nothing clear: coach adds nothing', (
    tester,
  ) async {
    final (feed, coach) = await _open(tester, eintrag: 'x', checkIn: false);
    expect(coach.calls, 0);
    expect(feed.durchgezogen, isEmpty);
  });

  testWidgets('add an own entry, open all, delete one', (tester) async {
    final (feed, _) = await _open(tester, vorher: [_e(4, 'Alte Sache.')]);
    await openTab(tester, 'Mindset');
    await scrollTo(tester, find.byKey(const ValueKey('durch-feld')));
    await tester.enterText(
      find.byKey(const ValueKey('durch-feld')),
      'Steuer abgeschickt',
    );
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('durch-eintragen')));
    await tester.pumpAndSettle();
    expect(feed.durchgezogen.last.text, 'Steuer abgeschickt');
    expect(feed.durchgezogen.last.vonCoach, isFalse);
    expect(find.text('DU'), findsOneWidget);

    await scrollTo(tester, find.byKey(const ValueKey('durch-alle')));
    await tester.tap(find.byKey(const ValueKey('durch-alle')));
    await tester.pumpAndSettle();
    expect(find.text('DIESE WOCHE'), findsOneWidget);
    expect(find.text('5. BIS 11. OKT'), findsOneWidget);
    expect(find.text('Alte Sache.'), findsOneWidget);

    await tester.tap(find.byTooltip('Löschen').last);
    await tester.pumpAndSettle();
    expect(find.text('Alte Sache.'), findsNothing);
    expect(feed.durchgezogen.map((e) => e.text), ['Steuer abgeschickt']);
  });
}
