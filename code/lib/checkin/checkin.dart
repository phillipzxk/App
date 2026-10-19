/// One daily check-in: the tapped answers per area, an optional note and
/// the AI reply.
///
/// Mirrors the table Check-ins in the vault (Datenstruktur/Check-ins.md).
class CheckIn {
  const CheckIn({
    required this.datum,
    required this.training,
    required this.ernaehrung,
    required this.schlaf,
    required this.mindset,
    this.energie = '',
    this.notiz = '',
    this.kiAntwort = '',
    this.werte = const {},
    this.gruende = const {},
  });

  /// Day of the check-in, without time.
  final DateTime datum;
  final String training;
  final String ernaehrung;
  final String schlaf;
  final String mindset;
  final String energie;

  /// Optional "Was war heute besonders?".
  final String notiz;

  /// The AI reply to the whole day; empty until the AI is connected.
  final String kiAntwort;

  /// The coach's score per area (Bereich.name -> 1..10, 10 = läuft super),
  /// see Umsetzung/Bereichs-Werte.md. Empty until rated.
  final Map<String, int> werte;

  /// One short sentence per area: why the score is where it is.
  final Map<String, String> gruende;

  Map<String, Object> toJson() => {
    'datum': dayKey(datum),
    'training': training,
    'ernaehrung': ernaehrung,
    'schlaf': schlaf,
    'mindset': mindset,
    'energie': energie,
    'notiz': notiz,
    'ki_antwort': kiAntwort,
    'werte': werte,
    'gruende': gruende,
  };

  CheckIn withReply(String reply) => _copy(kiAntwort: reply);

  CheckIn withWerte(Map<String, BereichsWert> w) => _copy(
    werte: {for (final e in w.entries) e.key: e.value.wert},
    gruende: {for (final e in w.entries) e.key: e.value.grund},
  );

  CheckIn _copy({
    String? kiAntwort,
    Map<String, int>? werte,
    Map<String, String>? gruende,
  }) => CheckIn(
    datum: datum,
    training: training,
    ernaehrung: ernaehrung,
    schlaf: schlaf,
    mindset: mindset,
    energie: energie,
    notiz: notiz,
    kiAntwort: kiAntwort ?? this.kiAntwort,
    werte: werte ?? this.werte,
    gruende: gruende ?? this.gruende,
  );

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
    datum: DateTime.parse(json['datum'] as String),
    training: json['training'] as String? ?? '',
    ernaehrung: json['ernaehrung'] as String? ?? '',
    schlaf: json['schlaf'] as String? ?? '',
    mindset: json['mindset'] as String? ?? '',
    energie: json['energie'] as String? ?? '',
    notiz: json['notiz'] as String? ?? '',
    kiAntwort: json['ki_antwort'] as String? ?? '',
    werte: {
      for (final e in ((json['werte'] as Map?) ?? const {}).entries)
        if (e.value is num) e.key as String: (e.value as num).round(),
    },
    gruende: {
      for (final e in ((json['gruende'] as Map?) ?? const {}).entries)
        if (e.value is String) e.key as String: e.value as String,
    },
  );
}

/// The coach's score for one area on one day, with its reason.
class BereichsWert {
  const BereichsWert(this.wert, this.grund);

  /// 1..10, 10 = läuft super.
  final int wert;
  final String grund;
}

/// The date as yyyy-mm-dd, used as key and for comparing days.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
