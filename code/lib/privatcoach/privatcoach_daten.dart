// Privatcoach (vault Umsetzung/Phillip dazuholen.md, Ablauf 2026-11-21):
// users write to Phillip like on Insta, the first message is a request he
// accepts, he sees their shared values next to the chat.

enum ChatStatus { anfrage, aktiv, beendet }

/// One message. [vonCoach] is Phillip, written from his own account.
class CoachNachricht {
  const CoachNachricht({
    required this.id,
    required this.vonCoach,
    required this.text,
    required this.erstellt,
    this.chat = '',
    this.audio,
    this.sekunden,
    this.gelesen,
  });

  final int id;
  final bool vonCoach;
  final String text;
  final DateTime erstellt;

  /// The chat's user id.
  final String chat;

  /// Storage path of a voice message.
  final String? audio;
  final int? sekunden;
  final DateTime? gelesen;

  factory CoachNachricht.fromJson(Map<String, Object?> j) => CoachNachricht(
    id: (j['id'] as num).toInt(),
    vonCoach: j['von'] == 'coach',
    text: j['text'] as String? ?? '',
    erstellt: DateTime.parse(j['erstellt'] as String).toLocal(),
    chat: j['chat'] as String? ?? '',
    audio: j['audio'] as String?,
    sekunden: (j['audio_sekunden'] as num?)?.toInt(),
    gelesen: j['gelesen'] == null
        ? null
        : DateTime.parse(j['gelesen'] as String).toLocal(),
  );
}

/// One area in the shared values: name, today's score and the week.
class WertBereich {
  const WertBereich({
    required this.name,
    this.wert,
    this.diff,
    this.woche = const [],
  });
  final String name;
  final int? wert;
  final int? diff;
  final List<int?> woche;

  Map<String, Object?> toJson() => {
    'name': name,
    'wert': wert,
    'diff': diff,
    'woche': woche,
  };

  factory WertBereich.fromJson(Map<String, Object?> j) => WertBereich(
    name: j['name'] as String? ?? '',
    wert: (j['wert'] as num?)?.toInt(),
    diff: (j['diff'] as num?)?.toInt(),
    woche: [
      for (final x in (j['woche'] as List?) ?? const []) (x as num?)?.toInt(),
    ],
  );
}

/// What the user shares with Phillip ("Darf Phillip deine Werte sehen?"):
/// areas, pattern, sleep, focus, goal and why.
class GeteilteWerte {
  const GeteilteWerte({
    this.bereiche = const [],
    this.muster,
    this.schlafStunden = const [],
    this.fokus,
    this.ziel,
    this.warum,
    this.seitTagen,
  });

  final List<WertBereich> bereiche;
  final String? muster;

  /// The last 7 nights in hours, oldest first (null = nothing entered).
  final List<double?> schlafStunden;
  final String? fokus;
  final String? ziel;
  final String? warum;

  /// Days since the first check-in.
  final int? seitTagen;

  double? get schlafSchnitt {
    final da = [for (final s in schlafStunden) ?s];
    return da.isEmpty ? null : da.reduce((a, b) => a + b) / da.length;
  }

  Map<String, Object?> toJson() => {
    'bereiche': [for (final b in bereiche) b.toJson()],
    'muster': muster,
    'schlaf': schlafStunden,
    'fokus': fokus,
    'ziel': ziel,
    'warum': warum,
    'seit': seitTagen,
  };

  factory GeteilteWerte.fromJson(Map<String, Object?> j) => GeteilteWerte(
    bereiche: [
      for (final b in (j['bereiche'] as List?) ?? const [])
        WertBereich.fromJson((b as Map).cast<String, Object?>()),
    ],
    muster: j['muster'] as String?,
    schlafStunden: [
      for (final s in (j['schlaf'] as List?) ?? const [])
        (s as num?)?.toDouble(),
    ],
    fokus: j['fokus'] as String?,
    ziel: j['ziel'] as String?,
    warum: j['warum'] as String?,
    seitTagen: (j['seit'] as num?)?.toInt(),
  );
}

/// One chat: the user's own, or for Phillip one row in his inbox.
class CoachChat {
  const CoachChat({
    required this.userId,
    required this.name,
    required this.status,
    this.werteErlaubt = false,
    this.werte,
    this.fokus,
    this.zuletzt,
    this.letzte,
    this.ungelesen = 0,
  });

  final String userId;
  final String name;
  final ChatStatus status;
  final bool werteErlaubt;
  final GeteilteWerte? werte;

  /// The focus Phillip set ("Fokus anpassen").
  final String? fokus;
  final DateTime? zuletzt;

  /// The newest message, for the inbox row.
  final CoachNachricht? letzte;

  /// Messages from the other side not read yet.
  final int ungelesen;

  CoachChat copyWith({CoachNachricht? letzte, int? ungelesen}) => CoachChat(
    userId: userId,
    name: name,
    status: status,
    werteErlaubt: werteErlaubt,
    werte: werte,
    fokus: fokus,
    zuletzt: zuletzt,
    letzte: letzte ?? this.letzte,
    ungelesen: ungelesen ?? this.ungelesen,
  );

  factory CoachChat.fromJson(Map<String, Object?> j) => CoachChat(
    userId: j['user_id'] as String,
    name: j['name'] as String? ?? '',
    status: ChatStatus.values.asNameMap()[j['status']] ?? ChatStatus.anfrage,
    werteErlaubt: j['werte_erlaubt'] == true,
    werte: j['werte'] is Map
        ? GeteilteWerte.fromJson((j['werte'] as Map).cast<String, Object?>())
        : null,
    fokus: j['fokus'] as String?,
    zuletzt: j['zuletzt'] == null
        ? null
        : DateTime.parse(j['zuletzt'] as String).toLocal(),
  );
}

/// "12:31", "Gestern", "Mo" or "21.11." like on Insta.
String chatZeit(DateTime t, DateTime jetzt) {
  final heute = DateTime(jetzt.year, jetzt.month, jetzt.day);
  final tag = DateTime(t.year, t.month, t.day);
  final d = heute.difference(tag).inDays;
  if (d <= 0) {
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
  if (d == 1) return 'Gestern';
  if (d < 7) {
    return const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'][t.weekday - 1];
  }
  return '${t.day}.${t.month}.';
}

/// "0:24" for a voice message.
String dauerText(int sekunden) =>
    '${sekunden ~/ 60}:${(sekunden % 60).toString().padLeft(2, '0')}';
