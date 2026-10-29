import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/feed/kcal.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/sleep/sleep.dart';
import 'package:coach_app/weight/weight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(
  ziel: 'Frei sein',
  motivation: 'Ich will stolz auf mich sein.',
);

Future<(MemoryDiaryStore, MemoryFeedStore)> _openFeed(
  WidgetTester tester, {
  MemoryFeedStore? feed,
}) async {
  final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
  final f = feed ?? MemoryFeedStore();
  tallView(tester);
  await tester.pumpWidget(
    CoachApp(
      store: MemoryProfileStore(_profile),
      diary: diary,
      feed: f,
      clock: fixedClock,
    ),
  );
  await tester.pumpAndSettle();
  return (diary, f);
}

void main() {
  test('kcal target from Mifflin-St Jeor and activity, rounded to 50', () {
    const p = KcalProfil(
      groesseCm: 180,
      alter: 30,
      geschlecht: Geschlecht.mann,
      aktivitaet: Aktivitaet.aktiv,
    );
    // (824 + 1125 - 150 + 5) * 1.55 = 2796.2
    expect(kcalZiel(p, 82.4), 2800);
    expect(formatKcal(2800), '2.800');
    expect(formatKcal(950), '950');
  });

  test('short day label for the week overview', () {
    expect(shortDay('Oberkörper: Bankdrücken 3x8'), 'Oberkörper');
    expect(shortDay('Laufen 5 km'), 'Laufen 5 km');
    expect(shortDay('  '), 'frei');
    expect(shortDay('Push, Laufen\nBankdrücken 5x5'), 'Push, Laufen');
  });

  test('plan day keeps name and any number of exercises', () {
    final tag = joinDay('Push + Laufen', 'Bankdrücken 5x5\nDips 3x10');
    expect(tag, 'Push + Laufen\nBankdrücken 5x5\nDips 3x10');
    expect(dayDetails(tag), 'Bankdrücken 5x5\nDips 3x10');
    expect(dayDetails('Oberkörper: Bankdrücken 3x8'), 'Bankdrücken 3x8');
    expect(dayDetails('Laufen 5 km'), '');
    expect(joinDay('', 'Laufen 5 km'), 'Laufen 5 km');
  });

  testWidgets('areas open big from the roots and lead to their page', (
    tester,
  ) async {
    await _openFeed(tester);
    expect(find.text('MONTAG, 12. OKTOBER'), findsOneWidget);
    expect(find.text('DEIN COACH · HEUTE'), findsOneWidget);

    // Schlaf opens in Körper with Schlaf & Routine picked.
    await openBereich(tester, 'schlaf');
    expect(find.text('Körper'), findsOneWidget);
    expect(find.text('Schlaf & Routine'), findsWidgets);
    expect(find.byKey(const ValueKey('kachel-s-himmel')), findsOneWidget);

    // Switch to Training directly at the top, then to its Plan page.
    await tester.tap(find.byKey(const ValueKey('teil-training')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kachel-t-heute')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('seite-Plan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kachel-t-plan')), findsOneWidget);

    // A tile grows into its page; back goes to Körper.
    await openKachel(tester, 't-plan');
    expect(find.text('Dein Plan'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
    await tester.pumpAndSettle();

    // Closing Körper goes back to the roots.
    await tester.tap(find.byKey(const ValueKey('bereich-zurueck')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('wurzel-schlaf')), findsOneWidget);

    await openTab(tester, 'Mindset');
    expect(find.byKey(const ValueKey('mindset-seite')), findsOneWidget);
    await zeigeKachel(tester, 'm-warum');
    expect(find.text('„Ich will stolz auf mich sein.“'), findsOneWidget);
  });

  testWidgets('training plan is saved with names, exercises and settings', (
    tester,
  ) async {
    final (_, feed) = await _openFeed(tester);
    await openTab(tester, 'Training', 't-heute');
    await tester.tap(find.text('Plan festlegen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sportart-Krafttraining')));
    await tester.tap(find.byKey(const ValueKey('sportart-Laufen')));
    await tester.tap(find.byKey(const ValueKey('plan-schwerpunkt-hybrid')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('plan-name-0')));
    await tester.enterText(
      find.byKey(const ValueKey('plan-name-0')),
      'Push + Laufen',
    );
    await scrollTo(tester, find.byKey(const ValueKey('plan-add-0')));
    await tester.tap(find.byKey(const ValueKey('plan-add-0')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('uebung-name')),
      'Bankdrücken',
    );
    await tester.enterText(find.byKey(const ValueKey('uebung-wert')), '80');
    await scrollTo(tester, find.byKey(const ValueKey('modus-Bereich')));
    await tester.tap(find.byKey(const ValueKey('modus-Bereich')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('plan-add-0')));
    await tester.tap(find.byKey(const ValueKey('plan-add-0')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('uebung-name')), 'Laufen');
    await scrollTo(tester, find.byKey(const ValueKey('art-Strecke')));
    await tester.tap(find.byKey(const ValueKey('art-Strecke')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('uebung-wert')), '5');
    await scrollTo(tester, find.byKey(const ValueKey('plan-name-1')));
    await tester.enterText(
      find.byKey(const ValueKey('plan-name-1')),
      'Kampfsport',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(
      feed.plan.tage[0],
      'Push + Laufen\nBankdrücken 3 × 8–10 80 kg\nLaufen 5 km',
    );
    expect(feed.plan.uebungenAm(0).first.wdhBis, 10);
    expect(feed.plan.uebungenAm(0).last.art.name, 'strecke');
    expect(feed.plan.tage[1], 'Kampfsport');
    expect(feed.training.sportarten, ['Krafttraining', 'Laufen']);
    expect(feed.schwerpunkt, Schwerpunkt.hybrid);
    expect(find.text('Heute: Push + Laufen'), findsOneWidget);
    expect(find.text('Letztes Mal'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('feld-zurueck')));
    await tester.pumpAndSettle();
    await openKachel(tester, 't-plan');
    await scrollTo(tester, find.byKey(const ValueKey('schwerpunkt-kraft')));
    await tester.tap(find.byKey(const ValueKey('schwerpunkt-kraft')));
    await tester.pumpAndSettle();
    expect(feed.schwerpunkt, Schwerpunkt.kraft);
  });

  testWidgets('training in Dein Tag opens the Training page', (tester) async {
    final (_, feed) = await _openFeed(
      tester,
      feed: MemoryFeedStore()
        ..plan = TrainingPlan([
          'Push + Laufen\nBankdrücken 5x5',
          ...List.filled(6, ''),
        ]),
    );
    expect(feed.plan.isEmpty, isFalse);
    await scrollTo(tester, find.byKey(const ValueKey('dein-tag')));
    await tester.tap(find.byKey(const ValueKey('dein-tag')));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('tag-training'));
    await tester.scrollUntilVisible(
      row.hitTestable(),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: row, matching: find.text('Push + Laufen')),
      findsOneWidget,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Heute: Push + Laufen'), findsOneWidget);
  });

  testWidgets('kcal setup asks for the first weight and shows the target', (
    tester,
  ) async {
    final (diary, feed) = await _openFeed(tester);
    await openTab(tester, 'Ernährung', 'e-kcal');
    await tester.tap(find.text('kcal-Ziel einrichten'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Bitte zwischen 120 und 230 cm.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Größe'), '180');
    await tester.enterText(find.widgetWithText(TextField, 'Alter'), '30');
    await tester.enterText(
      find.widgetWithText(TextField, 'Gewicht heute'),
      '82,4',
    );
    await tester.tap(find.text('Mann'));
    await scrollTo(tester, find.text('Aktiv'));
    await tester.tap(find.text('Aktiv'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(feed.kcal?.aktivitaet, Aktivitaet.aktiv);
    expect(diary.weights.single.kg, 82.4);
    expect(find.text('DEIN KCAL-ZIEL HEUTE'), findsOneWidget);
    expect(find.textContaining('2.800'), findsOneWidget);
  });

  testWidgets('kcal target follows the newest weight', (tester) async {
    final feed = MemoryFeedStore()
      ..kcal = const KcalProfil(
        groesseCm: 180,
        alter: 30,
        geschlecht: Geschlecht.mann,
        aktivitaet: Aktivitaet.aktiv,
      );
    final diary = MemoryDiaryStore()
      ..checkIns.add(checkInOn(fixedNow))
      ..weights.add(WeightEntry(DateTime(2026, 10, 1), 90));
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        clock: fixedClock,
      ),
    );
    await tester.pumpAndSettle();
    await openTab(tester, 'Ernährung', 'e-kcal');
    // (900 + 1125 - 150 + 5) * 1.55 = 2914
    expect(find.textContaining('2.900'), findsOneWidget);
  });

  testWidgets('evening routine is saved', (tester) async {
    final (_, feed) = await _openFeed(tester);
    await openTab(tester, 'Schlaf', 's-routine');
    await scrollTo(tester, find.text('Abendroutine festlegen'));
    await tester.tap(find.text('Abendroutine festlegen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '22:15'), '22:15');
    await tester.enterText(
      find.widgetWithText(TextField, 'Was machst du?'),
      'Handy weg',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(feed.routine.single.was, 'Handy weg');
    expect(find.text('Handy weg'), findsOneWidget);
    expect(find.text('Routine bearbeiten'), findsOneWidget);
  });

  testWidgets('writing to the coach saves it and shows the placeholder', (
    tester,
  ) async {
    final (_, feed) = await _openFeed(tester);
    await openTab(tester, 'Training');
    // The coach card opens "Frag den Coach".
    await tester.tap(find.byKey(const ValueKey('bereich-coach')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Wie war dein Training?'));
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Was hast du geschafft, was nicht, und warum? Der Coach sieht '
        'auch deine Einträge.',
      ),
      'Nur die Hälfte, war zu kaputt.',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Senden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Senden'));
    await tester.pumpAndSettle();

    expect(feed.fragen.single.bereich, Bereich.training);
    expect(find.text('Nur die Hälfte, war zu kaputt.'), findsOneWidget);
    expect(find.text('Folgt bald.'), findsOneWidget);
  });

  test('sleep hours parse, average and per-night list', () {
    expect(parseHours('7,5'), 7.5);
    expect(parseHours('7:30'), 7.5);
    expect(parseHours('7:75'), isNull);
    expect(parseHours('20'), isNull);
    final nights = lastNights(
      [
        SleepEntry(DateTime(2026, 10, 12, 7), 6),
        SleepEntry(DateTime(2026, 10, 10), 8),
      ],
      fixedNow,
      14,
    );
    expect(nights.length, 14);
    expect(nights.last, 6);
    expect(nights[11], 8);
    expect(nights[12], isNull);
    expect(average(nights.sublist(7)), 7);
  });

  testWidgets('sleep duration can be entered and shows the average', (
    tester,
  ) async {
    final (diary, _) = await _openFeed(tester);
    diary.sleep.add(SleepEntry(DateTime(2026, 10, 1), 6));
    await openTab(tester, 'Schlaf', 's-naechte');
    await scrollTo(tester, find.text('Schlaf eintragen'));
    await tester.tap(find.text('Schlaf eintragen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '7:30');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(diary.sleep.last.stunden, 7.5);
    await scrollTo(tester, find.text('Ø 7,5 Std.'));
    expect(find.text('Ø 7,5 Std.'), findsOneWidget);
    expect(find.text('+1,5 Std. zur Vorwoche'), findsOneWidget);
  });
}
