import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/supplements/supplement_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _profile = UserProfile(ziel: 'Frei sein', motivation: 'Stolz sein.');

const _kreatin = Supplement(zeit: '08:00', name: 'Kreatin', menge: '5 g');
const _magnesium = Supplement(zeit: '21:30', name: 'Magnesium');

void main() {
  test('normZeit reads short times', () {
    expect(normZeit('8'), '08:00');
    expect(normZeit('8.30'), '08:30');
    expect(normZeit('21:30'), '21:30');
    expect(normZeit('25'), isNull);
    expect(normZeit('abends'), isNull);
  });

  test('next open intake from now on, else the earliest open', () {
    // fixedNow is 18:00.
    expect(naechsteOffene([_kreatin, _magnesium], {}, fixedNow), _magnesium);
    expect(
      naechsteOffene([_kreatin, _magnesium], {_magnesium.id}, fixedNow),
      _kreatin,
    );
    expect(naechsteOffene([_kreatin], {_kreatin.id}, fixedNow), isNull);
  });

  Future<MemoryFeedStore> start(
    WidgetTester tester, {
    List<Supplement> supplements = const [],
  }) async {
    final diary = MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow));
    final feed = MemoryFeedStore()..supplements = List.of(supplements);
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
    return feed;
  }

  testWidgets('empty routine: no field on Heute', (tester) async {
    await start(tester);
    expect(find.byKey(const ValueKey('supp-hinweis')), findsNothing);
  });

  testWidgets('set up the routine on Ernährung', (tester) async {
    final feed = await start(tester);
    await openTab(tester, 'Ernährung');
    await scrollTo(tester, find.byKey(const ValueKey('supp-festlegen')));
    await tester.tap(find.byKey(const ValueKey('supp-festlegen')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('supp-zeit-0')), '8');
    await tester.enterText(
      find.byKey(const ValueKey('supp-name-0')),
      'Kreatin',
    );
    await tester.enterText(find.byKey(const ValueKey('supp-menge-0')), '5 g');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(feed.supplements.single.zeit, '08:00');
    expect(feed.supplements.single.menge, '5 g');
    expect(find.text('heute 0 von 1'), findsOneWidget);
  });

  testWidgets('a name without a valid time is not saved', (tester) async {
    final feed = await start(tester);
    await openTab(tester, 'Ernährung');
    await scrollTo(tester, find.byKey(const ValueKey('supp-festlegen')));
    await tester.tap(find.byKey(const ValueKey('supp-festlegen')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('supp-name-0')), 'Zink');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
    expect(find.text('Uhrzeit?'), findsOneWidget);
    expect(feed.supplements, isEmpty);
  });

  testWidgets('field on Heute leads to Ernährung, ticking updates it', (
    tester,
  ) async {
    final feed = await start(tester, supplements: [_magnesium, _kreatin]);
    await openBereich(tester, 'ernaehrung');
    expect(
      find.textContaining('2 offen, nächste 21:30 Magnesium'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('supp-hinweis')));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.byKey(const ValueKey('supp-check-1')));
    expect(find.text('heute 0 von 2'), findsOneWidget);

    // Sorted by time: index 1 is Magnesium.
    await tester.tap(find.byKey(const ValueKey('supp-check-1')));
    await tester.pumpAndSettle();
    expect(feed.genommen[dayKey(fixedNow)], {_magnesium.id});
    expect(find.text('heute 1 von 2'), findsOneWidget);

    await scrollTo(tester, find.byKey(const ValueKey('supp-check-0')));
    await tester.tap(find.byKey(const ValueKey('supp-check-0')));
    await tester.pumpAndSettle();
    await openTab(tester, 'Heute');
    // All taken: the field disappears from Heute.
    expect(find.byKey(const ValueKey('supp-hinweis')), findsNothing);

    // Untick again.
    await openTab(tester, 'Ernährung');
    await tester.tap(find.byKey(const ValueKey('supp-check-0')));
    await tester.pumpAndSettle();
    expect(find.text('heute 1 von 2'), findsOneWidget);
  });
}
