import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import 'ernaehrung_data.dart';

/// What the coach does on the Ernährung page. Every call may return null
/// (no coach or not reachable); the page then has its own fallback.
abstract class ErnaehrungCoach {
  /// One sentence on how food links to sleep, training and head, or null
  /// when nothing is clearly visible.
  Future<String?> zusammenhang(
    UserProfile profile,
    List<CheckIn> recent,
    String heisshunger,
    String schlaf,
  );

  /// One step for a craving right now.
  Future<String?> heisshunger(
    UserProfile profile,
    String grund,
    String uhrzeit,
    String kontext,
  );

  /// The rough read of a plate photo.
  Future<TellerHinweis?> teller(
    UserProfile profile,
    String mahlzeit,
    String bild,
  );

  /// A dish from the fridge: from a photo, or again from a corrected list.
  Future<({List<String> zutaten, Gericht? gericht})?> kuehlschrank(
    UserProfile profile,
    String kontext, {
    String? bild,
    List<String>? zutaten,
  });

  /// Rescue dishes, each against one of the user's patterns.
  Future<List<Gericht>?> rettung(
    UserProfile profile,
    String muster,
    String vorhanden,
    int anzahl,
  );

  /// The Gewichts-Check after the user's own guess.
  Future<({String sicht, String? vorschlag, int? kcalNeu})?> gewicht(
    UserProfile profile,
    String verlauf,
    int kcal,
    String grund,
    String kontext,
  );
}

class NoErnaehrungCoach implements ErnaehrungCoach {
  const NoErnaehrungCoach();

  @override
  Future<String?> zusammenhang(
    UserProfile profile,
    List<CheckIn> recent,
    String heisshunger,
    String schlaf,
  ) async => null;

  @override
  Future<String?> heisshunger(
    UserProfile profile,
    String grund,
    String uhrzeit,
    String kontext,
  ) async => null;

  @override
  Future<TellerHinweis?> teller(
    UserProfile profile,
    String mahlzeit,
    String bild,
  ) async => null;

  @override
  Future<({List<String> zutaten, Gericht? gericht})?> kuehlschrank(
    UserProfile profile,
    String kontext, {
    String? bild,
    List<String>? zutaten,
  }) async => null;

  @override
  Future<List<Gericht>?> rettung(
    UserProfile profile,
    String muster,
    String vorhanden,
    int anzahl,
  ) async => null;

  @override
  Future<({String sicht, String? vorschlag, int? kcalNeu})?> gewicht(
    UserProfile profile,
    String verlauf,
    int kcal,
    String grund,
    String kontext,
  ) async => null;
}

/// The reasons the coach asks for when a craving comes.
const heisshungerGruende = [
  'Echter Hunger',
  'Stress',
  'Langeweile',
  'Müde',
  'Gewohnheit',
];

/// A step for a craving when the coach is not reachable.
String heisshungerOhneCoach(String grund) => switch (grund) {
  'Echter Hunger' =>
    'Dann ist es kein Heißhunger, sondern zu wenig gegessen. Iss jetzt eine '
        'richtige Kleinigkeit mit Eiweiß, zum Beispiel Quark oder Eier.',
  'Stress' =>
    'Dein Kopf will gerade Ruhe, nicht Essen. Erst 10 Minuten raus oder ein '
        'Glas Wasser, dann entscheidest du nochmal. Wenn du dann noch was '
        'willst: eine Portion, auf einen Teller, im Sitzen.',
  'Langeweile' =>
    'Steh auf und mach 10 Minuten etwas anderes, weg von der Küche. Meist '
        'ist es danach weg. Wenn nicht, iss bewusst eine kleine Portion.',
  'Müde' =>
    'Müde Tage machen Hunger. Heute nicht kämpfen: eine Kleinigkeit mit '
        'Eiweiß, und heute Abend 30 Minuten früher ins Bett.',
  _ =>
    'Um diese Zeit isst du oft etwas. Stell dir vorher eine Kleinigkeit hin, '
        'zum Beispiel Quark oder Obst, dann greifst du nicht zur Schublade.',
};

/// Rescue dishes when the coach is not reachable.
List<Gericht> rettungOhneCoach(String idBasis) => [
  Gericht(
    id: '$idBasis-1',
    name: 'Skyr-Bowl mit Nüssen',
    art: 'Snack',
    dauer: 5,
    gegen: 'gegen Heißhunger am Abend',
    warum:
        'Süß, viel Eiweiß und schnell gemacht. Steht schneller auf dem Tisch '
        'als die Schublade aufgeht.',
    quelle: 'coach',
    zutaten: const [
      Zutat(name: 'Skyr', menge: 200, einheit: 'g', gruppe: 'Kühlregal'),
      Zutat(name: 'Banane', menge: 1, einheit: 'Stück', gruppe: 'Obst'),
      Zutat(name: 'Walnüsse', menge: 20, einheit: 'g', gruppe: 'Vorrat'),
      Zutat(name: 'Honig', menge: 1, einheit: 'TL', gruppe: 'Vorrat'),
    ],
    schritte: const [
      'Skyr in eine Schale.',
      'Banane in Scheiben drauf.',
      'Nüsse grob hacken, mit Honig drüber.',
    ],
  ),
  Gericht(
    id: '$idBasis-2',
    name: 'Linsen-Bolognese',
    dauer: 25,
    gegen: 'für späte Trainingstage',
    warum:
        'Einmal für zwei Tage kochen. Viel Eiweiß, lange satt, und nach einem '
        'späten Training in 5 Minuten warm.',
    quelle: 'coach',
    zutaten: const [
      Zutat(name: 'Rote Linsen', menge: 80, einheit: 'g', gruppe: 'Vorrat'),
      Zutat(name: 'Rinderhack', menge: 125, einheit: 'g', gruppe: 'Eiweiß'),
      Zutat(
        name: 'Passierte Tomaten',
        menge: 250,
        einheit: 'ml',
        gruppe: 'Vorrat',
      ),
      Zutat(name: 'Zwiebel', menge: 1, einheit: 'Stück', gruppe: 'Gemüse'),
      Zutat(name: 'Vollkornnudeln', menge: 100, einheit: 'g', gruppe: 'Vorrat'),
    ],
    schritte: const [
      'Zwiebel klein schneiden, mit dem Hack anbraten.',
      'Linsen und Tomaten dazu, 15 Minuten köcheln.',
      'Nudeln kochen, alles mischen.',
      'Zweite Portion in eine Box für den nächsten späten Tag.',
    ],
  ),
  Gericht(
    id: '$idBasis-3',
    name: 'Rührei-Wrap mit Spinat',
    art: 'Frühstück',
    dauer: 10,
    gegen: 'für Tage mit wenig Schlaf',
    warum:
        'Nach kurzen Nächten willst du schnell was Süßes. Das hier ist in 10 '
        'Minuten fertig und hält bis mittags.',
    quelle: 'coach',
    zutaten: const [
      Zutat(name: 'Eier', menge: 3, einheit: 'Stück', gruppe: 'Kühlregal'),
      Zutat(
        name: 'Vollkorn-Wrap',
        menge: 1,
        einheit: 'Stück',
        gruppe: 'Vorrat',
      ),
      Zutat(name: 'Spinat', menge: 50, einheit: 'g', gruppe: 'Gemüse'),
      Zutat(name: 'Feta', menge: 30, einheit: 'g', gruppe: 'Kühlregal'),
    ],
    schritte: const [
      'Eier verquirlen, in der Pfanne stocken lassen.',
      'Spinat kurz mitbraten.',
      'Auf den Wrap, Feta drüber, einrollen.',
    ],
  ),
];

/// Takes one photo and returns it as JPEG base64, null when cancelled.
typedef FotoAufnahme = Future<String?> Function();

/// Replaced in tests.
FotoAufnahme fotoAufnahme = () async {
  final f = await ImagePicker().pickImage(
    source: ImageSource.camera,
    maxWidth: 900,
    maxHeight: 900,
    imageQuality: 70,
  );
  if (f == null) return null;
  return base64Encode(await f.readAsBytes());
};
