import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/ernaehrung/ernaehrung_logik.dart';
import 'package:coach_app/feed/feed_coach.dart';
import 'package:coach_app/feed/feed_data.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/schnell/schnell_eintrag.dart';
import 'package:coach_app/training/training_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(name: 'Phillip', ziel: 'Mehr Muskeln');

class _Coach extends NoFeedCoach implements SchnellCoach {
  String? gesagt;

  @override
  Future<SchnellAntwort?> schnell(
    UserProfile profile,
    String text,
    String kontext,
  ) async {
    gesagt = text;
    return SchnellAntwort(
      satz: 'Hab ich, vier Sachen.',
      eintraege: [
        SchnellEintrag.fromJson({
          'art': 'training',
          'titel': 'Bankdrücken 80 kg · 3 × 8',
          'uebung': 'Bankdrücken',
          'kg': 80,
          'wdh': 8,
          'saetze': 3,
        })!,
        SchnellEintrag.fromJson({
          'art': 'termin',
          'titel': 'Morgen 10:00 Zahnarzt',
          'text': 'Zahnarzt',
          'tag': 1,
          'zeit': '10:00',
        })!,
        SchnellEintrag.fromJson({
          'art': 'durchgezogen',
          'titel': 'Steuererklärung angefangen',
          'text': 'Steuererklärung angefangen',
          'unsicher': true,
          'frage': 'Zählt das als durchgezogen?',
        })!,
        SchnellEintrag.fromJson({
          'art': 'notiz',
          'titel': 'Fühle mich heute stark',
          'bereich': 'mindset',
        })!,
      ],
    );
  }
}

MahlzeitSlot _slot(String id, int minute, {bool snack = false}) =>
    MahlzeitSlot(id: id, name: id, minute: minute, snack: snack, tipp: '');

void main() {
  group('logic', () {
    test('only serious follow-ups, at most two', () {
      final f = gegenfragen(
        jetzt: 15 * 60,
        trainingName: 'Push',
        trainingMinute: 13 * 60,
        mahlzeiten: [
          _slot('fruehstueck', 8 * 60),
          _slot('snack1', 10 * 60, snack: true),
          _slot('mittag', 12 * 60 + 30),
          _slot('abend', 19 * 60),
        ],
        gegessen: {'fruehstueck'},
      );
      expect(f.map((g) => g.id), ['training', 'mahlzeit-mittag']);
      expect(f.first.frage, contains('13:00'));
    });

    test('nothing asked that was just said or is not due yet', () {
      final f = gegenfragen(
        jetzt: 13 * 60,
        trainingName: 'Push',
        trainingMinute: 12 * 60 + 30,
        mahlzeiten: [_slot('mittag', 12 * 60)],
        eintraege: [
          const SchnellEintrag(
            art: 'mahlzeit',
            titel: 'Mittag',
            daten: {'mahlzeit': 'mittag'},
          ),
        ],
      );
      expect(f, isEmpty);
    });

    test('a meal goes to its open slot, else the nearest', () {
      final slots = [
        _slot('fruehstueck', 8 * 60),
        _slot('mittag', 12 * 60),
        _slot('abend', 19 * 60),
      ];
      const mittag = SchnellEintrag(
        art: 'mahlzeit',
        titel: 'x',
        daten: {'mahlzeit': 'mittag'},
      );
      expect(slotFuer(mittag, slots, {}, 13 * 60)!.id, 'mittag');
      expect(slotFuer(mittag, slots, {'mittag'}, 13 * 60)!.id, 'fruehstueck');
      expect(slotFuer(mittag, const [], {}, 13 * 60), isNull);
    });
  });

  testWidgets('say it once, the entries land in their areas', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()
      ..plan = TrainingPlan(['Push 16:00', '', '', '', '', '', '']);
    final coach = _Coach();
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        feedCoach: coach,
        clock: () => fixedNow,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schnell-knopf')));
    await tester.pumpAndSettle();
    expect(find.text('Was gibt\'s, Phillip?'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('schnell-feld')),
      'Bankdrücken 80 Kilo 3 mal 8, morgen 10 Uhr Zahnarzt',
    );
    await tester.tap(find.byKey(const ValueKey('schnell-senden')));
    await tester.pumpAndSettle();
    expect(coach.gesagt, contains('Zahnarzt'));
    expect(find.text('Hab ich, vier Sachen.'), findsOneWidget);
    expect(find.text('Morgen 10:00 Zahnarzt'), findsOneWidget);
    // Training is in the text, so no follow-up about it.
    expect(find.textContaining('geplant'), findsNothing);

    // The unsure one is kept with "Ja"; the note is taken out.
    await tester.tap(find.byKey(const ValueKey('schnell-ja-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schnell-weg-3')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('schnell-fertig')));
    await tester.tap(find.byKey(const ValueKey('schnell-fertig')));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final einheit = feed.training.einheitAm(fixedNow)!;
    expect(einheit.name, 'Push');
    expect(einheit.uebungen.single.name, 'Bankdrücken');
    expect(einheit.uebungen.single.fertige, hasLength(3));
    expect(einheit.uebungen.single.bester!.wert, 80);
    final t = feed.termine.single;
    expect(dayKey(t.datum), dayKey(fixedNow.add(const Duration(days: 1))));
    expect(t.zeit, '10:00');
    expect(feed.durchgezogen.single.text, 'Steuererklärung angefangen');
    expect(feed.fragen, isEmpty);
  });

  testWidgets('a follow-up adds the planned training on yes', (tester) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()
      ..plan = TrainingPlan(['Push 16:00', '', '', '', '', '', '']);
    tallView(tester);
    await tester.pumpWidget(
      CoachApp(
        store: MemoryProfileStore(_profile),
        diary: diary,
        feed: feed,
        feedCoach: _NurNotiz(),
        clock: () => fixedNow,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schnell-knopf')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('schnell-feld')), 'x');
    await tester.tap(find.byKey(const ValueKey('schnell-senden')));
    await tester.pumpAndSettle();
    expect(find.textContaining('16:00 geplant'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schnell-ja-1')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('schnell-fertig')));
    await tester.tap(find.byKey(const ValueKey('schnell-fertig')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(feed.training.einheitAm(fixedNow)!.status, EinheitStatus.fertig);
    expect(feed.fragen.single.text, 'Gut geschlafen');
  });
}

class _NurNotiz extends NoFeedCoach implements SchnellCoach {
  @override
  Future<SchnellAntwort?> schnell(UserProfile p, String t, String k) async =>
      SchnellAntwort(
        eintraege: [
          SchnellEintrag.fromJson({
            'art': 'notiz',
            'titel': 'Gut geschlafen',
            'bereich': 'schlaf',
          })!,
        ],
      );
}
