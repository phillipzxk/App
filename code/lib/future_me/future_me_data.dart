import '../checkin/checkin.dart';

/// What the user sets up once for "Dein zukünftiges Ich" (see
/// Umsetzung/Dein zukünftiges Ich.md): the fixed photo day, their own poses
/// and up to three own performance values.
class FotoEinstellungen {
  const FotoEinstellungen({
    required this.fototag,
    required this.posen,
    required this.werte,
  });

  /// Weekday of the photo, as in [DateTime.weekday] (7 = Sunday). Stays
  /// fixed once chosen.
  final int fototag;

  /// E.g. ["Vorne", "Seite"]; at least one.
  final List<String> posen;

  /// Names in the user's own words, e.g. "Klimmzüge am Stück"; up to 3.
  final List<String> werte;

  FotoEinstellungen copyWith({List<String>? posen, List<String>? werte}) =>
      FotoEinstellungen(
        fototag: fototag,
        posen: posen ?? this.posen,
        werte: werte ?? this.werte,
      );

  Map<String, dynamic> toJson() => {
    'fototag': fototag,
    'posen': posen,
    'werte': werte,
  };

  factory FotoEinstellungen.fromJson(Map<String, dynamic> json) =>
      FotoEinstellungen(
        fototag: json['fototag'] as int,
        posen: [for (final p in json['posen'] as List) p as String],
        werte: [for (final w in json['werte'] as List) w as String],
      );
}

/// One week's photos and values. Photos stay on the phone only.
class WochenFoto {
  const WochenFoto({
    required this.fototag,
    required this.gemacht,
    required this.bilder,
    required this.werte,
  });

  /// The photo day this entry belongs to (time of day ignored).
  final DateTime fototag;

  /// When it was actually taken: the photo day or, caught up, the day after.
  final DateTime gemacht;

  /// Pose name to the photo, as base64 JPEG.
  final Map<String, String> bilder;

  /// Value name to what the user entered, e.g. "9" or "25:55".
  final Map<String, String> werte;

  bool get nachgeholt => dayKey(gemacht) != dayKey(fototag);

  Map<String, dynamic> toJson() => {
    'fototag': fototag.toIso8601String(),
    'gemacht': gemacht.toIso8601String(),
    'bilder': bilder,
    'werte': werte,
  };

  factory WochenFoto.fromJson(Map<String, dynamic> json) => WochenFoto(
    fototag: DateTime.parse(json['fototag'] as String),
    gemacht: DateTime.parse(json['gemacht'] as String),
    bilder: Map<String, String>.from(json['bilder'] as Map),
    werte: Map<String, String>.from(json['werte'] as Map),
  );
}

enum FotoStatus {
  /// Today is the photo day and the photo is not taken yet.
  heute,

  /// Yesterday was the photo day and it was missed; today it can be caught
  /// up once.
  nachholen,

  /// Nothing to do today; [FotoLage.tag] is the next photo day.
  spaeter,
}

class FotoLage {
  const FotoLage(this.status, this.tag, this.woche);

  final FotoStatus status;

  /// The photo day the status is about: today, yesterday or the next one.
  final DateTime tag;

  /// Week number of [tag], counted from the first photo (week 1).
  final int woche;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

int _daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool _hasPhoto(List<WochenFoto> fotos, DateTime fototag) =>
    fotos.any((f) => dayKey(f.fototag) == dayKey(fototag));

/// Week number of [fototag]: week 1 is the first photo, or [fototag] itself
/// when there is none yet.
int wocheVon(List<WochenFoto> fotos, DateTime fototag) {
  if (fotos.isEmpty) return 1;
  return _daysBetween(fotos.first.fototag, fototag) ~/ 7 + 1;
}

/// Where the user stands today: photo due, catch-up allowed (only the day
/// after a missed photo day), or the next photo day.
FotoLage fotoLage(DateTime now, FotoEinstellungen e, List<WochenFoto> fotos) {
  final today = _day(now);
  if (today.weekday == e.fototag && !_hasPhoto(fotos, today)) {
    return FotoLage(FotoStatus.heute, today, wocheVon(fotos, today));
  }
  final yesterday = _addDays(today, -1);
  if (yesterday.weekday == e.fototag && !_hasPhoto(fotos, yesterday)) {
    return FotoLage(
      FotoStatus.nachholen,
      yesterday,
      wocheVon(fotos, yesterday),
    );
  }
  var next = _addDays(today, (e.fototag - today.weekday) % 7);
  if (!next.isAfter(today)) next = _addDays(next, 7);
  return FotoLage(FotoStatus.spaeter, next, wocheVon(fotos, next));
}

/// One slot in the row of all weeks: the week's photo, or null for a missed
/// week.
class WochenPlatz {
  const WochenPlatz(this.woche, this.fototag, this.foto);

  final int woche;
  final DateTime fototag;
  final WochenFoto? foto;
}

/// All weeks from the first photo on, oldest first. A week counts as
/// missed only once its catch-up day is over.
List<WochenPlatz> alleWochen(DateTime now, List<WochenFoto> fotos) {
  if (fotos.isEmpty) return const [];
  final today = _day(now);
  final byDay = {for (final f in fotos) dayKey(f.fototag): f};
  final result = <WochenPlatz>[];
  var day = _day(fotos.first.fototag);
  for (var w = 1; ; w++) {
    final foto = byDay[dayKey(day)];
    if (foto == null && _daysBetween(day, today) <= 1) break;
    result.add(WochenPlatz(w, day, foto));
    day = _addDays(day, 7);
  }
  return result;
}

const wochentage = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];
