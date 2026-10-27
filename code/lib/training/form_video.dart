import '../checkin/checkin.dart';

/// One filmed set (idea 10): the stills the coach looked at, the set it
/// belongs to and the "Hinweise vom Coach" (vault Umsetzung/Training
/// eintragen.md). The full video comes with the phone version; until then
/// the stills are what is kept.
class FormVideo {
  const FormVideo({
    required this.id,
    required this.uebung,
    required this.datum,
    required this.satz,
    required this.bilder,
    this.hinweise,
  });

  final String id;
  final String uebung;
  final DateTime datum;

  /// E.g. "82,5 kg × 8".
  final String satz;

  /// The stills as base64 JPEG, in time order.
  final List<String> bilder;
  final FormHinweise? hinweise;

  FormVideo mitHinweisen(FormHinweise h) => FormVideo(
    id: id,
    uebung: uebung,
    datum: datum,
    satz: satz,
    bilder: bilder,
    hinweise: h,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'uebung': uebung,
    'datum': dayKey(datum),
    'satz': satz,
    'bilder': bilder,
    if (hinweise != null) 'hinweise': hinweise!.toJson(),
  };

  factory FormVideo.fromJson(Map<String, dynamic> j) => FormVideo(
    id: j['id'] as String,
    uebung: j['uebung'] as String,
    datum: DateTime.parse(j['datum'] as String),
    satz: j['satz'] as String? ?? '',
    bilder: [for (final b in j['bilder'] as List? ?? const []) '$b'],
    hinweise: j['hinweise'] == null
        ? null
        : FormHinweise.fromJson(j['hinweise'] as Map<String, dynamic>),
  );
}

/// What the coach saw: what is good, what can be better (with the still
/// it shows in), and a comparison with the last video.
class FormHinweise {
  const FormHinweise({
    this.gut = const [],
    this.besser = const [],
    this.vergleich,
  });

  final List<String> gut;
  final List<({String text, int? bild})> besser;
  final String? vergleich;

  bool get leer => gut.isEmpty && besser.isEmpty;

  /// All hints as plain text, for the next comparison.
  String get text => [
    for (final g in gut) 'Gut: $g',
    for (final b in besser) 'Besser: ${b.text}',
  ].join('\n');

  Map<String, dynamic> toJson() => {
    'gut': gut,
    'besser': [
      for (final b in besser) {'text': b.text, 'bild': b.bild},
    ],
    'vergleich': vergleich,
  };

  factory FormHinweise.fromJson(Map<String, dynamic> j) => FormHinweise(
    gut: [for (final g in j['gut'] as List? ?? const []) '$g'],
    besser: [
      for (final b in j['besser'] as List? ?? const [])
        (
          text: (b as Map)['text'] as String? ?? '',
          bild: (b['bild'] as num?)?.toInt(),
        ),
    ],
    vergleich: j['vergleich'] as String?,
  );
}

/// Keeps the newest three videos per exercise, so the phone does not fill.
List<FormVideo> formVideosKuerzen(List<FormVideo> list) {
  final out = <FormVideo>[];
  final zahl = <String, int>{};
  for (final v in list.reversed) {
    final k = v.uebung.toLowerCase();
    zahl[k] = (zahl[k] ?? 0) + 1;
    if (zahl[k]! <= 3) out.add(v);
  }
  return out.reversed.toList();
}
