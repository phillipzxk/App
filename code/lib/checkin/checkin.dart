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

  Map<String, Object> toJson() => {
    'datum': dayKey(datum),
    'training': training,
    'ernaehrung': ernaehrung,
    'schlaf': schlaf,
    'mindset': mindset,
    'energie': energie,
    'notiz': notiz,
    'ki_antwort': kiAntwort,
  };

  CheckIn withReply(String reply) => CheckIn(
    datum: datum,
    training: training,
    ernaehrung: ernaehrung,
    schlaf: schlaf,
    mindset: mindset,
    energie: energie,
    notiz: notiz,
    kiAntwort: reply,
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
  );
}

/// The date as yyyy-mm-dd, used as key and for comparing days.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
