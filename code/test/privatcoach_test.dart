import 'package:coach_app/data/user_profile.dart';
import 'package:coach_app/ui/umbau.dart';
import 'package:coach_app/main.dart';
import 'package:coach_app/privatcoach/privatcoach_daten.dart';
import 'package:coach_app/privatcoach/privatcoach_dienst.dart';
import 'package:coach_app/privatcoach/privatcoach_seiten.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

final _jetzt = DateTime(2026, 11, 21, 10);

const _werte = GeteilteWerte(
  bereiche: [
    WertBereich(
      name: 'Körper',
      wert: 6,
      diff: -1,
      woche: [7, 7, 6, 7, 6, 7, 6],
    ),
  ],
  muster: 'Nach kurzen Nächten Heißhunger',
  schlafStunden: [6, 7, null, 6.5, 7, 8, 6],
  fokus: 'Abends Handy weg',
  ziel: 'Mehr durchziehen',
  warum: 'Stolz sein.',
  seitTagen: 12,
);

Future<void> _zeige(WidgetTester tester, Widget seite) async {
  tallView(tester);
  await tester.pumpWidget(MaterialApp(home: seite));
  await tester.pumpAndSettle();
}

/// Ends the page so its fetch timer stops.
Future<void> _ende(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('first message asks about the values and opens a request', (
    tester,
  ) async {
    final d = MemoryPrivatcoach(id: 'u1', clock: () => _jetzt);
    await _zeige(
      tester,
      ChatSeite(
        dienst: d,
        chatId: 'u1',
        name: 'Max',
        werte: () async => _werte,
        clock: () => _jetzt,
      ),
    );
    expect(
      find.text('Schreib mir, wo es gerade hängt. Ich antworte selbst.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const ValueKey('chat-feld')), 'Hallo');
    await tester.tap(find.byKey(const ValueKey('chat-senden')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('werte-frage')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('werte-erlauben')));
    await tester.pumpAndSettle();

    final chat = d.chats['u1']!;
    expect(chat.status, ChatStatus.anfrage);
    expect(chat.name, 'Max');
    expect(chat.werteErlaubt, isTrue);
    expect(chat.werte?.fokus, 'Abends Handy weg');
    expect(find.text('Hallo'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-anfrage')), findsOneWidget);
    await _ende(tester);
  });

  testWidgets('"Nur Nachricht" sends without the values', (tester) async {
    final d = MemoryPrivatcoach(id: 'u1', clock: () => _jetzt);
    await _zeige(
      tester,
      ChatSeite(
        dienst: d,
        chatId: 'u1',
        name: 'Max',
        werte: () async => _werte,
        clock: () => _jetzt,
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('chat-feld')), 'Hi');
    await tester.tap(find.byKey(const ValueKey('chat-senden')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('werte-nur-nachricht')));
    await tester.pumpAndSettle();
    expect(d.chats['u1']!.werteErlaubt, isFalse);
    expect(d.chats['u1']!.werte, isNull);
    await _ende(tester);
  });

  testWidgets('full: "Gerade voll" and no field', (tester) async {
    final d = MemoryPrivatcoach(id: 'neu', plaetze: 1, clock: () => _jetzt);
    d.schreiben('anders', 'Hi', vonCoach: false, name: 'Lena');
    await _zeige(
      tester,
      ChatSeite(dienst: d, chatId: 'neu', name: 'Max', clock: () => _jetzt),
    );
    expect(find.byKey(const ValueKey('chat-voll')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-feld')), findsNothing);
    await _ende(tester);
  });

  testWidgets('Phillip accepts a request and answers', (tester) async {
    final d = MemoryPrivatcoach(
      coach: true,
      id: 'phillip',
      clock: () => _jetzt,
    );
    d.schreiben('u1', 'Ich hänge abends fest', vonCoach: false, name: 'Max');
    await _zeige(tester, PostEingang(dienst: d, clock: () => _jetzt));

    expect(find.byKey(const ValueKey('eingang-u1')), findsOneWidget);
    expect(find.text('Anfrage'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('eingang-u1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-annehmen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-annehmen')));
    await tester.pumpAndSettle();
    expect(d.chats['u1']!.status, ChatStatus.aktiv);

    await tester.enterText(
      find.byKey(const ValueKey('chat-feld')),
      'Was passiert um 21 Uhr?',
    );
    await tester.tap(find.byKey(const ValueKey('chat-senden')));
    await tester.pumpAndSettle();
    final n = d.verlauf['u1']!;
    expect(n.last.vonCoach, isTrue);
    expect(n.last.text, 'Was passiert um 21 Uhr?');
    // Opening marked the user's message as read.
    expect(n.first.gelesen, isNotNull);
    await _ende(tester);
  });

  testWidgets('inbox: unread tab shows only unread chats', (tester) async {
    final d = MemoryPrivatcoach(
      coach: true,
      id: 'phillip',
      clock: () => _jetzt,
    );
    d.schreiben('u1', 'Hallo', vonCoach: false, name: 'Max');
    d.schreiben('u2', 'Servus', vonCoach: false, name: 'Lena');
    d.angenommen('u2');
    await d.gelesen('u2');
    await _zeige(tester, PostEingang(dienst: d, clock: () => _jetzt));
    expect(find.byKey(const ValueKey('eingang-u2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('eingang-ungelesen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('eingang-u1')), findsOneWidget);
    expect(find.byKey(const ValueKey('eingang-u2')), findsNothing);
    await _ende(tester);
  });

  testWidgets('Phillip adjusts the focus, the user sees it', (tester) async {
    final d = MemoryPrivatcoach(
      coach: true,
      id: 'phillip',
      clock: () => _jetzt,
    );
    d.schreiben('u1', 'Hallo', vonCoach: false, name: 'Max');
    d.chats['u1'] = CoachChat(
      userId: 'u1',
      name: 'Max',
      status: ChatStatus.aktiv,
      werteErlaubt: true,
      werte: _werte,
      zuletzt: _jetzt,
    );
    d.angenommen('u1');
    await _zeige(
      tester,
      GeteilteWerteSeite(dienst: d, chat: (await d.alleChats()).first),
    );
    expect(find.text('Nach kurzen Nächten Heißhunger'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fokus-anpassen')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('fokus-feld')),
      'Ab 21 Uhr Handy weg',
    );
    await tester.tap(find.byKey(const ValueKey('fokus-speichern')));
    await tester.pumpAndSettle();
    expect(d.chats['u1']!.fokus, 'Ab 21 Uhr Handy weg');

    // On the user's side the focus card appears.
    final nutzer = MemoryPrivatcoach(id: 'u1', clock: () => _jetzt)
      ..chats.addAll(d.chats)
      ..verlauf.addAll(d.verlauf);
    await _zeige(
      tester,
      ChatSeite(dienst: nutzer, chatId: 'u1', name: 'Max', clock: () => _jetzt),
    );
    expect(find.byKey(const ValueKey('chat-fokus')), findsOneWidget);
    expect(find.text('Ab 21 Uhr Handy weg'), findsOneWidget);
    await _ende(tester);
  });

  testWidgets('home: P in the corner, in the bar after accepting', (
    tester,
  ) async {
    final d = MemoryPrivatcoach(id: 'u1', clock: () => fixedNow);
    Future<void> oeffne() async {
      tallView(tester);
      await tester.pumpWidget(
        CoachApp(
          store: MemoryProfileStore(
            const UserProfile(name: 'Max', ziel: 'Mehr durchziehen'),
          ),
          diary: MemoryDiaryStore()..checkIns.add(checkInOn(fixedNow)),
          feed: MemoryFeedStore(),
          clock: () => fixedNow,
          privatcoach: d,
        ),
      );
      await tester.pumpAndSettle();
    }

    await oeffne();
    expect(find.byKey(const ValueKey('privatcoach-ecke')), findsOneWidget);
    expect(find.byKey(const ValueKey('leiste-p')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('privatcoach-ecke')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-feld')), 'Hallo');
    await tester.tap(find.byKey(const ValueKey('chat-senden')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('werte-erlauben')));
    await tester.pumpAndSettle();
    // The values come from the app itself.
    expect(d.chats['u1']!.werte?.ziel, 'Mehr durchziehen');
    expect(d.chats['u1']!.werte?.bereiche, isNotEmpty);

    d.angenommen('u1');
    d.schreiben('u1', 'Erzähl mal', vonCoach: true);
    await tester.tap(find.byType(ZurueckPille));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('privatcoach-ecke')), findsNothing);
    expect(find.byKey(const ValueKey('leiste-p')), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    await _ende(tester);
  });

  test('chat times read like a messenger', () {
    expect(chatZeit(DateTime(2026, 11, 21, 9, 5), _jetzt), '09:05');
    expect(dauerText(75), '1:15');
  });
}
