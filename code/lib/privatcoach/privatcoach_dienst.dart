import 'dart:convert';

import 'package:http/http.dart' as http;

import '../konto/konto_daten.dart';
import '../konto/konto_dienst.dart';
import 'privatcoach_daten.dart';

/// Why a message could not go out, in the user's words.
class ChatFehler implements Exception {
  const ChatFehler(this.text);
  final String text;
  @override
  String toString() => text;
}

/// The chat with Phillip on the server (backend/supabase/schema.sql, part 4).
/// Only Phillip's account writes as the coach; the server checks that.
abstract class PrivatcoachDienst {
  /// The signed-in account's id, null without an account.
  Future<String?> ich();

  /// Whether this account is Phillip's.
  Future<bool> istCoach();

  /// Whether a new user can still write (places in the test phase).
  Future<bool> frei();

  /// The user's own chat, null before the first message.
  Future<CoachChat?> meinChat();

  /// Phillip's inbox: all chats, newest first, with the last message.
  Future<List<CoachChat>> alleChats();

  Future<List<CoachNachricht>> nachrichten(String chat);

  /// Sends into [chat]. The user's first message opens the request.
  Future<void> senden(
    String chat,
    String text, {
    String? name,
    String? audio,
    int? sekunden,
  });

  /// Shares the values with Phillip, or stops sharing ([werte] null).
  Future<void> werteTeilen(GeteilteWerte? werte);

  Future<void> annehmen(String chat);
  Future<void> fokusSetzen(String chat, String fokus);

  /// Marks what the other side wrote as read.
  Future<void> gelesen(String chat);

  /// Saves this device's Web Push subscription for the signed-in person.
  Future<void> pushSpeichern(String endpoint, String p256dh, String auth);
}

/// Over Supabase with the account from Konto und Sicherung.
class SupabasePrivatcoach implements PrivatcoachDienst {
  SupabasePrivatcoach({
    required this.url,
    required this.key,
    required this.dienst,
    required this.store,
    this.clock = DateTime.now,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final String url;
  final String key;
  final KontoDienst dienst;
  final KontoStore store;
  final DateTime Function() clock;
  final http.Client _http;

  bool? _coach;

  Future<Konto?> _konto() async {
    var k = await store.loadKonto();
    if (k == null) return null;
    if (k.abgelaufen(clock())) {
      k = await dienst.erneuern(k);
      await store.saveKonto(k);
    }
    return k;
  }

  Future<Map<String, String>> _kopf() async {
    final k = await _konto();
    if (k == null) throw const ChatFehler('Melde dich zuerst an.');
    return {
      'apikey': key,
      'Authorization': 'Bearer ${k.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  Future<Object?> _rpc(String name, Map<String, Object?> args) async {
    final r = await _http.post(
      Uri.parse('$url/rest/v1/rpc/$name'),
      headers: await _kopf(),
      body: jsonEncode(args),
    );
    if (r.statusCode >= 300) {
      final m = r.body;
      if (m.contains('voll')) {
        throw const ChatFehler('Gerade sind alle Plätze belegt.');
      }
      if (m.contains('beendet')) {
        throw const ChatFehler('Euer Coaching ist beendet.');
      }
      throw const ChatFehler(
        'Das hat nicht geklappt. Prüf dein Internet und versuch es nochmal.',
      );
    }
    return r.body.isEmpty ? null : jsonDecode(r.body);
  }

  Future<List<Map<String, Object?>>> _lies(String pfad) async {
    final r = await _http.get(
      Uri.parse('$url/rest/v1/$pfad'),
      headers: await _kopf(),
    );
    if (r.statusCode >= 300) {
      throw const ChatFehler('Konnte den Chat gerade nicht laden.');
    }
    return [
      for (final x in jsonDecode(r.body) as List)
        (x as Map).cast<String, Object?>(),
    ];
  }

  @override
  Future<String?> ich() async => (await store.loadKonto())?.id;

  @override
  Future<bool> istCoach() async {
    if (_coach != null) return _coach!;
    if (await store.loadKonto() == null) return false;
    try {
      return _coach = await _rpc('ist_coach', const {}) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> frei() async {
    try {
      return await _rpc('coach_frei', const {}) == true;
    } catch (_) {
      return true;
    }
  }

  @override
  Future<CoachChat?> meinChat() async {
    final id = await ich();
    if (id == null) return null;
    final l = await _lies('coach_chats?user_id=eq.$id&select=*');
    if (l.isEmpty) return null;
    final c = CoachChat.fromJson(l.first);
    final n = await nachrichten(id);
    return c.copyWith(
      letzte: n.isEmpty ? null : n.last,
      ungelesen: n.where((x) => x.vonCoach && x.gelesen == null).length,
    );
  }

  @override
  Future<List<CoachChat>> alleChats() async {
    final chats = [
      for (final j in await _lies('coach_chats?select=*&order=zuletzt.desc'))
        CoachChat.fromJson(j),
    ];
    final alle = [
      for (final j in await _lies(
        'coach_nachrichten?select=*&order=id.desc&limit=1000',
      ))
        CoachNachricht.fromJson(j),
    ];
    return [
      for (final c in chats)
        c.copyWith(
          letzte: alle.where((n) => n.chat == c.userId).firstOrNull,
          ungelesen: alle
              .where(
                (n) => n.chat == c.userId && !n.vonCoach && n.gelesen == null,
              )
              .length,
        ),
    ];
  }

  @override
  Future<List<CoachNachricht>> nachrichten(String chat) async => [
    for (final j in await _lies(
      'coach_nachrichten?chat=eq.$chat&select=*&order=id.asc',
    ))
      CoachNachricht.fromJson(j),
  ];

  @override
  Future<void> senden(
    String chat,
    String text, {
    String? name,
    String? audio,
    int? sekunden,
  }) => _rpc('coach_senden', {
    'p_chat': chat,
    'p_text': text,
    'p_audio': audio,
    'p_sekunden': sekunden,
    'p_name': name,
  });

  @override
  Future<void> werteTeilen(GeteilteWerte? werte) => _rpc('coach_werte', {
    'p_erlaubt': werte != null,
    'p_werte': werte?.toJson(),
  });

  @override
  Future<void> annehmen(String chat) =>
      _rpc('coach_annehmen', {'p_chat': chat});

  @override
  Future<void> fokusSetzen(String chat, String fokus) =>
      _rpc('coach_fokus', {'p_chat': chat, 'p_fokus': fokus});

  @override
  Future<void> gelesen(String chat) async {
    try {
      await _rpc('coach_gelesen', {'p_chat': chat});
    } catch (_) {}
  }

  @override
  Future<void> pushSpeichern(String endpoint, String p256dh, String auth) =>
      _rpc('coach_push_an', {
        'p_endpoint': endpoint,
        'p_p256dh': p256dh,
        'p_auth': auth,
      });
}

/// Tests and the preview without a server: everything in memory. [coach]
/// shows Phillip's side.
class MemoryPrivatcoach implements PrivatcoachDienst {
  MemoryPrivatcoach({
    this.coach = false,
    this.id = 'ich',
    this.plaetze = 5,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final bool coach;
  final String id;
  int plaetze;
  final DateTime Function() clock;

  final chats = <String, CoachChat>{};
  final verlauf = <String, List<CoachNachricht>>{};
  var _naechste = 1;

  @override
  Future<String?> ich() async => id;

  @override
  Future<bool> istCoach() async => coach;

  @override
  Future<bool> frei() async =>
      chats.values.where((c) => c.status != ChatStatus.beendet).length <
      plaetze;

  CoachChat _mit(CoachChat c, bool fuerCoach) {
    final n = verlauf[c.userId] ?? const [];
    return c.copyWith(
      letzte: n.isEmpty ? null : n.last,
      ungelesen: n
          .where((x) => x.vonCoach != fuerCoach && x.gelesen == null)
          .length,
    );
  }

  @override
  Future<CoachChat?> meinChat() async {
    final c = chats[id];
    return c == null ? null : _mit(c, false);
  }

  @override
  Future<List<CoachChat>> alleChats() async => [
    for (final c
        in chats.values.toList()..sort(
          (a, b) =>
              (b.zuletzt ?? DateTime(0)).compareTo(a.zuletzt ?? DateTime(0)),
        ))
      _mit(c, true),
  ];

  @override
  Future<List<CoachNachricht>> nachrichten(String chat) async =>
      List.of(verlauf[chat] ?? const []);

  /// For tests and the preview: as if someone else wrote.
  void schreiben(
    String chat,
    String text, {
    required bool vonCoach,
    String name = '',
  }) {
    chats.putIfAbsent(
      chat,
      () => CoachChat(userId: chat, name: name, status: ChatStatus.anfrage),
    );
    final c = chats[chat]!;
    chats[chat] = CoachChat(
      userId: c.userId,
      name: c.name.isEmpty ? name : c.name,
      status: c.status,
      werteErlaubt: c.werteErlaubt,
      werte: c.werte,
      fokus: c.fokus,
      zuletzt: clock(),
    );
    (verlauf[chat] ??= []).add(
      CoachNachricht(
        id: _naechste++,
        vonCoach: vonCoach,
        text: text,
        erstellt: clock(),
        chat: chat,
      ),
    );
  }

  void _status(
    String chat,
    ChatStatus s, {
    GeteilteWerte? werte,
    bool? erlaubt,
    String? fokus,
  }) {
    final c = chats[chat]!;
    chats[chat] = CoachChat(
      userId: c.userId,
      name: c.name,
      status: s,
      werteErlaubt: erlaubt ?? c.werteErlaubt,
      werte: erlaubt == false ? null : (werte ?? c.werte),
      fokus: fokus ?? c.fokus,
      zuletzt: c.zuletzt,
    );
  }

  @override
  Future<void> senden(
    String chat,
    String text, {
    String? name,
    String? audio,
    int? sekunden,
  }) async {
    if (!coach && !chats.containsKey(chat) && !await frei()) {
      throw const ChatFehler('Gerade sind alle Plätze belegt.');
    }
    if (coach && chats[chat]?.status != ChatStatus.aktiv) {
      throw const ChatFehler('Nimm die Anfrage zuerst an.');
    }
    schreiben(chat, text, vonCoach: coach, name: name ?? '');
  }

  @override
  Future<void> werteTeilen(GeteilteWerte? werte) async {
    if (!chats.containsKey(id)) return;
    _status(id, chats[id]!.status, werte: werte, erlaubt: werte != null);
  }

  @override
  Future<void> annehmen(String chat) async => _status(chat, ChatStatus.aktiv);

  /// For tests and the preview: as if Phillip accepted.
  void angenommen(String chat) => _status(chat, ChatStatus.aktiv);

  @override
  Future<void> fokusSetzen(String chat, String fokus) async =>
      _status(chat, chats[chat]!.status, fokus: fokus);

  /// Saved push subscriptions (tests).
  final push = <String>[];

  @override
  Future<void> pushSpeichern(
    String endpoint,
    String p256dh,
    String auth,
  ) async => push.add(endpoint);

  @override
  Future<void> gelesen(String chat) async {
    final l = verlauf[chat];
    if (l == null) return;
    for (var i = 0; i < l.length; i++) {
      final n = l[i];
      if (n.vonCoach != coach && n.gelesen == null) {
        l[i] = CoachNachricht(
          id: n.id,
          vonCoach: n.vonCoach,
          text: n.text,
          erstellt: n.erstellt,
          chat: n.chat,
          audio: n.audio,
          sekunden: n.sekunden,
          gelesen: clock(),
        );
      }
    }
  }
}
