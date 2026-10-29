import 'package:flutter/material.dart';

import '../bereiche/glas.dart';
import '../checkin/checkin.dart';
import '../data/user_profile.dart';
import '../mindset/dranbleiben.dart' show GoldRing;
import '../mindset/mindset_logik.dart' show wocheVon;
import '../mindset/mindset_ui.dart';
import '../ui/coach_style.dart';
import 'business_bilder.dart';
import 'business_coach.dart';
import 'business_data.dart';
import 'business_logik.dart';

/// Work done (the Produktivität value) on days with and without training
/// and after short nights, as averages 1..10.
typedef ArbeitKoerper = ({double? mit, double? ohne, double? kurz, int tage});

/// What every Business page needs.
class BusinessUmfeld {
  const BusinessUmfeld({
    required this.stand,
    required this.profile,
    required this.coach,
    required this.jetzt,
    this.koerper,
  });

  final BusinessStand stand;
  final UserProfile profile;
  final BusinessCoach coach;
  final DateTime Function() jetzt;
  final ArbeitKoerper? koerper;

  String get heute => dayKey(jetzt());
  String get woche => wocheVon(jetzt());
  String get kontext => businessKontext(stand.d, jetzt());
}

/// Base for the pages: rebuilds on every change and runs coach calls with
/// a busy state.
abstract class _Seite<T extends StatefulWidget> extends State<T> {
  BusinessUmfeld get u;
  BusinessDaten get d => u.stand.d;
  bool busy = false;

  Future<void> warte(Future<void> Function() f) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await f();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void offline() {
    if (mounted) hinweis(context, 'Der Coach ist gerade nicht erreichbar.');
  }

  Widget inhalt(BuildContext context);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: u.stand,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [inhalt(context)],
    ),
  );
}

Widget _spalte(List<Widget> c) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: c);

Widget _gross(String t, {double size = 22}) => Text(
  t,
  style: CoachStyle.title.copyWith(
    fontSize: size,
    height: 1.25,
    color: Glas.text,
  ),
);

class _Nummer extends StatelessWidget {
  const _Nummer({
    required this.n,
    required this.titel,
    this.text,
    this.gold = false,
  });
  final int n;
  final String titel;
  final String? text;
  final bool gold;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gold ? CoachStyle.goldGradient : null,
            border: gold ? null : Border.all(color: const Color(0x44FFEECD)),
          ),
          child: Text(
            '$n',
            style: Glas.tLabel.copyWith(
              color: gold ? CoachStyle.goldInk : Glas.label,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titel,
                style: Glas.tText.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (text != null && text!.isNotEmpty)
                Text(text!, style: Glas.tSoft),
            ],
          ),
        ),
      ],
    ),
  );
}

// ------------------------------------------------------------ Hebel

class HebelSeite extends StatefulWidget {
  const HebelSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<HebelSeite> createState() => _HebelSeiteState();
}

class _HebelSeiteState extends _Seite<HebelSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _text = TextEditingController();
  final _schritte = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    _schritte.dispose();
    super.dispose();
  }

  Future<void> _vorschlag() => warte(() async {
    final r = await u.coach.hebel(u.profile, u.kontext);
    if (r == null) return offline();
    await u.stand.setze(
      d.mitHebel(
        Hebel(
          woche: u.woche,
          text: r.hebel,
          punkte: [for (final p in r.punkte) Punkt(p)],
          tipps: r.tipps,
        ),
      ),
    );
  });

  Future<void> _setzen() => warte(() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    final punkte = [
      for (final s in _schritte.text.split(RegExp(r'[\n,]')))
        if (s.trim().isNotEmpty) Punkt(s.trim()),
    ];
    final h = Hebel(woche: u.woche, text: t, punkte: punkte);
    await u.stand.setze(d.mitHebel(h));
    _text.clear();
    _schritte.clear();
    final tipps = await u.coach.tipps(u.profile, t, u.kontext);
    if (tipps != null) {
      await u.stand.setze(
        d.mitHebel(d.hebelIn(u.woche)!.copyWith(tipps: tipps)),
      );
    }
  });

  @override
  Widget inhalt(BuildContext context) {
    final h = d.hebelIn(u.woche);
    if (h == null) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Dein Hebel diese Woche',
          children: [
            Text(
              'Eine Aktion, die diese Woche am meisten bewegt.',
              style: Glas.tSoft,
            ),
            const SizedBox(height: 12),
            GlasKnopf(
              key: const ValueKey('hebel-vorschlag'),
              label: busy ? 'Einen Moment …' : 'Coach schlägt einen vor',
              onTap: busy ? null : _vorschlag,
            ),
          ],
        ),
        Block(
          label: 'Oder selbst festlegen',
          children: [
            GlasFeld(
              key: const ValueKey('hebel-feld'),
              controller: _text,
              hint: 'z. B. 3 frühere Kunden nach Empfehlungen fragen',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('hebel-schritte'),
              controller: _schritte,
              hint: 'Einzelne Schritte, mit Komma getrennt',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('hebel-setzen'),
              label: 'Festlegen',
              ghost: true,
              onTap: busy ? null : _setzen,
            ),
          ],
        ),
      ]);
    }
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Dein Hebel diese Woche',
        rechts: 'bis Sonntag',
        children: [
          _gross(h.text),
          const SizedBox(height: 8),
          for (var i = 0; i < h.punkte.length; i++)
            HakenZeile(
              key: ValueKey('hebel-punkt-$i'),
              an: h.punkte[i].an,
              titel: h.punkte[i].text,
              rechts: h.punkte[i].an ? 'erledigt' : 'offen',
              onTap: () {
                final p = [...h.punkte];
                p[i] = p[i].umschalten(u.heute);
                u.stand.setze(d.mitHebel(h.copyWith(punkte: p)));
              },
            ),
        ],
      ),
      Block(
        label: 'Tipps vom Coach, auf die man nicht kommt',
        children: [
          if (h.tipps.isEmpty)
            Text('Kommen, sobald der Coach erreichbar ist.', style: Glas.tSoft)
          else
            for (var k = 0; k < h.tipps.length; k++)
              _Nummer(
                n: k + 1,
                titel: h.tipps[k].titel,
                text: h.tipps[k].text,
                gold: k == 0,
              ),
        ],
      ),
      Block(
        label: 'Woche im Business',
        children: [
          Text(
            'Am Ende der Woche schaut der Reality Check, ob der Hebel '
            'umgesetzt wurde und was er gebracht hat.',
            style: Glas.tSoft,
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Mutige Anfrage

class AnfrageSeite extends StatefulWidget {
  const AnfrageSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<AnfrageSeite> createState() => _AnfrageSeiteState();
}

class _AnfrageSeiteState extends _Seite<AnfrageSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final n = d.anfragen.where((a) => a.an).length;
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          Center(child: Spross(n: n, size: 120)),
          const SizedBox(height: 6),
          Center(
            child: GoldSchrift(
              '$n geschafft',
              style: Glas.tBig.copyWith(fontSize: 26),
            ),
          ),
          Center(
            child: Text(
              'Jede mutige Anfrage lässt ein Blatt wachsen',
              style: Glas.tSoft,
            ),
          ),
        ],
      ),
      Block(
        label: 'Fällt dir schwer · so viele du willst',
        children: [
          for (var i = 0; i < d.anfragen.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      d.anfragen[i].text,
                      style: Glas.tText.copyWith(
                        fontSize: 14.5,
                        color: d.anfragen[i].an ? Glas.soft : Glas.text,
                        decoration: d.anfragen[i].an
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: CoachStyle.goldLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlasChip(
                    key: ValueKey('anfrage-$i'),
                    label: d.anfragen[i].an ? 'geschafft' : 'Geschafft',
                    an: d.anfragen[i].an,
                    onTap: () {
                      final l = [...d.anfragen];
                      l[i] = l[i].umschalten(u.heute);
                      u.stand.setze(d.copyWith(anfragen: l));
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('anfrage-feld'),
            controller: _text,
            hint: 'Was traust du dich noch nicht?',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('anfrage-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              final t = _text.text.trim();
              if (t.isEmpty) return;
              u.stand.setze(d.copyWith(anfragen: [...d.anfragen, Punkt(t)]));
              _text.clear();
            },
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Erster Euro

class EuroSeite extends StatefulWidget {
  const EuroSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<EuroSeite> createState() => _EuroSeiteState();
}

class _EuroSeiteState extends _Seite<EuroSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _idee = TextEditingController();
  final _angebot = TextEditingController();
  final _preis = TextEditingController();

  @override
  void dispose() {
    _idee.dispose();
    _angebot.dispose();
    _preis.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final e = d.euro;
    final schritte = [
      ('Angebot in einem Satz', e.angebot, e.angebot != null),
      (
        'Preis festlegen',
        e.preis == null ? null : '${euro(e.preis!)}, kein Rabatt',
        e.preis != null,
      ),
      ('3 Leuten schicken', null, e.geschickt),
      ('Der erste Euro', null, e.da != null),
    ];
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          Center(
            child: GoldSchrift(
              e.da != null && e.preis != null ? euro(e.preis!) : '0 €',
              style: Glas.tBig.copyWith(fontSize: 46),
            ),
          ),
          Center(
            child: Text(
              e.da != null
                  ? 'Der erste Euro ist da'
                  : 'die kleinste Version, die jemand kauft',
              style: Glas.tSoft,
            ),
          ),
        ],
      ),
      Block(
        label: e.angebot ?? 'Dein Weg zum ersten Euro',
        children: [
          for (var k = 0; k < schritte.length; k++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  GlasHaken(
                    key: ValueKey('euro-schritt-$k'),
                    an: schritte[k].$3,
                    onTap: () {
                      if (k == 2) {
                        u.stand.setze(
                          d.copyWith(euro: e.copyWith(geschickt: !e.geschickt)),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schritte[k].$1,
                          style: Glas.tText.copyWith(fontSize: 14.5),
                        ),
                        if (schritte[k].$2 != null)
                          Text(schritte[k].$2!, style: Glas.tSoft),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      if (e.angebot == null || e.preis == null)
        Block(
          label: 'Angebot und Preis',
          children: [
            GlasFeld(
              key: const ValueKey('euro-idee'),
              controller: _idee,
              hint: 'Was kannst du verkaufen? Ein paar Worte reichen',
            ),
            const SizedBox(height: 8),
            GlasKnopf(
              key: const ValueKey('euro-coach'),
              label: busy ? 'Einen Moment …' : 'Coach macht ein Angebot daraus',
              ghost: true,
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final i = _idee.text.trim();
                      if (i.isEmpty) return;
                      final r = await u.coach.ersterEuro(
                        u.profile,
                        i,
                        u.kontext,
                      );
                      if (r == null) return offline();
                      _angebot.text = r.angebot;
                      if (r.preis != null) _preis.text = '${r.preis}';
                    }),
            ),
            const SizedBox(height: 10),
            GlasFeld(
              key: const ValueKey('euro-angebot'),
              controller: _angebot,
              hint: '„Dein Logo in 5 Tagen, 3 Entwürfe, 149 €.“',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('euro-preis'),
              controller: _preis,
              hint: 'Preis in €',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('euro-speichern'),
              label: 'Übernehmen',
              onTap: () {
                final a = _angebot.text.trim();
                final p = zahl(_preis.text)?.round();
                if (a.isEmpty && p == null) return;
                u.stand.setze(
                  d.copyWith(
                    euro: e.copyWith(angebot: a.isEmpty ? null : a, preis: p),
                  ),
                );
              },
            ),
          ],
        ),
      const SizedBox(height: 14),
      if (e.da == null)
        GlasKnopf(
          key: const ValueKey('euro-da'),
          label: 'Der erste Euro ist da',
          onTap: e.angebot == null
              ? null
              : () {
                  u.stand.setze(
                    d.copyWith(
                      euro: e.copyWith(da: u.heute),
                      eingaenge: [
                        ...d.eingaenge,
                        if (e.preis != null)
                          Eingang(
                            tag: u.heute,
                            betrag: e.preis!,
                            wofuer: e.angebot,
                          ),
                      ],
                    ),
                  );
                  grossesHaken(context);
                },
        )
      else
        Center(
          child: TextButton(
            key: const ValueKey('euro-neu'),
            onPressed: () =>
                u.stand.setze(d.copyWith(euro: const ErsterEuro())),
            child: Text('Nächstes Angebot', style: Glas.tSoft),
          ),
        ),
    ]);
  }
}

// ------------------------------------------------------------ Umsatz-Ziel

class UmsatzSeite extends StatefulWidget {
  const UmsatzSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<UmsatzSeite> createState() => _UmsatzSeiteState();
}

class _UmsatzSeiteState extends _Seite<UmsatzSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _ziel = TextEditingController();
  final _betrag = TextEditingController();
  bool _aendern = false;

  @override
  void dispose() {
    _ziel.dispose();
    _betrag.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final jetzt = u.jetzt();
    final monat = monatVon(jetzt);
    final ziel = d.ziele[monat];
    final um = umsatzIm(d, monat);
    if (ziel == null || _aendern) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Umsatz-Ziel für ${monatName(jetzt)}',
          children: [
            GlasFeld(
              key: const ValueKey('ziel-feld'),
              controller: _ziel,
              hint: 'z. B. 3.000',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('ziel-setzen'),
              label: 'Ziel setzen',
              onTap: () {
                final z = zahl(_ziel.text)?.round();
                if (z == null || z <= 0) return;
                u.stand.setze(d.copyWith(ziele: {...d.ziele, monat: z}));
                setState(() => _aendern = false);
              },
            ),
          ],
        ),
      ]);
    }
    final rest = ziel - um;
    final heute = [
      for (final e in d.eingaenge)
        if (e.tag.startsWith(monat)) e,
    ].reversed.take(5).toList();
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          Center(
            child: GoldRing(
              key: const ValueKey('umsatz-ring'),
              anteil: um / ziel,
              text: euro(um),
              size: 170,
              dicke: 13,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'von ${euro(ziel)} · ${monatName(jetzt)} · noch ${restTage(jetzt)} Tage',
              style: Glas.tSoft,
            ),
          ),
        ],
      ),
      Block(
        label: 'Eingang eintragen',
        children: [
          GlasFeld(
            key: const ValueKey('umsatz-feld'),
            controller: _betrag,
            hint: 'Betrag in €',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('umsatz-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              final b = zahl(_betrag.text)?.round();
              if (b == null || b <= 0) return;
              final vorher = um;
              u.stand.setze(
                d.copyWith(
                  eingaenge: [
                    ...d.eingaenge,
                    Eingang(tag: u.heute, betrag: b),
                  ],
                ),
              );
              _betrag.clear();
              if (vorher < ziel && vorher + b >= ziel) grossesHaken(context);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Nur die Summe. Für Buchhaltung gibt es andere Apps.',
            style: Glas.tSoft,
          ),
          for (final e in heute)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.wofuer ?? 'Eingang', style: Glas.tSoft),
                  ),
                  Text(
                    euro(e.betrag),
                    style: Glas.tText.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
      Block(
        children: [
          CoachZeile(
            rest <= 0
                ? 'Ziel geschafft. Alles, was jetzt noch kommt, ist Vorsprung für den nächsten Monat.'
                : 'Noch ${euro(rest)} bis zu deinem Ziel.'
                      '${besteTaetigkeit(d) == null ? '' : ' Am meisten bringt dir gerade ${besteTaetigkeit(d)!.name}.'}',
          ),
        ],
      ),
      Center(
        child: TextButton(
          key: const ValueKey('ziel-aendern'),
          onPressed: () {
            _ziel.text = '$ziel';
            setState(() => _aendern = true);
          },
          child: Text('Ziel ändern', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------ Spar-Plan

class SparSeite extends StatefulWidget {
  const SparSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<SparSeite> createState() => _SparSeiteState();
}

class _SparSeiteState extends _Seite<SparSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _name = TextEditingController();
  final _ziel = TextEditingController();
  final _monat = TextEditingController();
  final _rein = TextEditingController();
  final _frage = TextEditingController();
  final _ausgaben = TextEditingController();
  String? _antwort;
  String? _satz;

  @override
  void dispose() {
    for (final c in [_name, _ziel, _monat, _rein, _frage, _ausgaben]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final s = d.spar;
    return _spalte([
      if (s == null)
        Block(
          art: GlasArt.gold,
          label: 'Spar-Ziel',
          children: [
            GlasFeld(
              key: const ValueKey('spar-name'),
              controller: _name,
              hint: 'Wofür? z. B. Neuer Laptop',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('spar-ziel'),
              controller: _ziel,
              hint: 'Wie viel? in €',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('spar-monat'),
              controller: _monat,
              hint: 'Pro Monat zurücklegen, in €',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('spar-setzen'),
              label: 'Festlegen',
              onTap: () {
                final n = _name.text.trim();
                final z = zahl(_ziel.text)?.round();
                if (n.isEmpty || z == null || z <= 0) return;
                u.stand.setze(
                  d.copyWith(
                    spar: SparZiel(
                      name: n,
                      ziel: z,
                      monatlich: zahl(_monat.text)?.round() ?? 0,
                    ),
                  ),
                );
              },
            ),
          ],
        )
      else
        Block(
          art: GlasArt.gold,
          label: 'Spar-Ziel',
          rechts: '${(s.anteil * 100).round()} %',
          children: [
            _gross(s.name, size: 21),
            const SizedBox(height: 10),
            GoldBalken(anteil: s.anteil),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${euro(s.stand)} von ${euro(s.ziel)}',
                    style: Glas.tSoft,
                  ),
                ),
                Text(
                  [
                    if (s.monatlich > 0) '${euro(s.monatlich)} im Monat',
                    ?sparFertig(s, u.jetzt()),
                  ].join(' · '),
                  style: Glas.tSoft,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GlasFeld(
                    key: const ValueKey('spar-rein'),
                    controller: _rein,
                    hint: 'Zurückgelegt, in €',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 110,
                  child: GlasKnopf(
                    key: const ValueKey('spar-dazu'),
                    label: 'Dazu',
                    ghost: true,
                    onTap: () {
                      final b = zahl(_rein.text)?.round();
                      if (b == null || b <= 0) return;
                      final vorher = s.stand;
                      u.stand.setze(
                        d.copyWith(spar: s.copyWith(stand: s.stand + b)),
                      );
                      _rein.clear();
                      if (vorher < s.ziel && vorher + b >= s.ziel) {
                        grossesHaken(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      Block(
        label: 'Lohnt sich das?',
        children: [
          GlasFeld(
            key: const ValueKey('lohnt-feld'),
            controller: _frage,
            hint: 'z. B. Neue Kamera für 900 €',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('lohnt-fragen'),
            label: busy ? 'Einen Moment …' : 'Fragen',
            ghost: true,
            onTap: busy
                ? null
                : () => warte(() async {
                    final f = _frage.text.trim();
                    if (f.isEmpty) return;
                    final a = await u.coach.lohntSich(u.profile, f, u.kontext);
                    if (a == null) return offline();
                    setState(() => _antwort = a);
                  }),
          ),
          if (_antwort != null) ...[
            const SizedBox(height: 10),
            CoachZeile(_antwort!),
          ],
        ],
      ),
      Block(
        label: 'Mehr sparen',
        children: [
          for (final t in d.sparTipps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.titel,
                    style: Glas.tText.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (t.text.isNotEmpty) Text(t.text, style: Glas.tSoft),
                ],
              ),
            ),
          if (_satz != null) ...[const SizedBox(height: 6), CoachZeile(_satz!)],
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('ausgaben-feld'),
            controller: _ausgaben,
            hint: 'Was kostet dich jeden Monat Geld? Abos, Essen, …',
            zeilen: 2,
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('spar-tipps'),
            label: busy ? 'Einen Moment …' : 'Tipps holen',
            ghost: true,
            onTap: busy
                ? null
                : () => warte(() async {
                    final a = _ausgaben.text.trim();
                    if (a.isEmpty) return;
                    final r = await u.coach.sparen(u.profile, a, u.kontext);
                    if (r == null) return offline();
                    await u.stand.setze(d.copyWith(sparTipps: r.tipps));
                    setState(() => _satz = r.satz);
                  }),
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Stundenwert

class StundeSeite extends StatefulWidget {
  const StundeSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<StundeSeite> createState() => _StundeSeiteState();
}

class _StundeSeiteState extends _Seite<StundeSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _name = TextEditingController();
  final _euro = TextEditingController();
  final _std = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _euro.dispose();
    _std.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final w = stundenwert(d);
    final max = d.taetigkeiten.fold<int>(
      1,
      (a, t) => (t.proStunde ?? 0) > a ? t.proStunde! : a,
    );
    final summe = d.taetigkeiten.fold<int>(0, (a, t) => a + t.euro);
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          Center(
            child: GoldSchrift(
              w == null ? '– €' : '$w €',
              style: Glas.tBig.copyWith(fontSize: 46),
            ),
          ),
          Center(
            child: Text(
              w == null
                  ? 'pro Stunde · trag ein, womit du Geld verdienst'
                  : 'pro Stunde · ${euro(summe)} durch ${stundenGesamt(d).round()} Stunden',
              style: Glas.tSoft,
            ),
          ),
        ],
      ),
      Block(
        label: 'Was dir pro Stunde bringt',
        rechts: 'diesen Monat',
        children: [
          for (var i = 0; i < d.taetigkeiten.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.taetigkeiten[i].name,
                          style: Glas.tText.copyWith(fontSize: 14.5),
                        ),
                      ),
                      Text(
                        '${d.taetigkeiten[i].proStunde ?? 0} €',
                        style: Glas.tLabel,
                      ),
                      IconButton(
                        key: ValueKey('taetigkeit-weg-$i'),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Glas.soft,
                        ),
                        onPressed: () => u.stand.setze(
                          d.copyWith(
                            taetigkeiten: [...d.taetigkeiten]..removeAt(i),
                          ),
                        ),
                      ),
                    ],
                  ),
                  GoldBalken(
                    anteil: (d.taetigkeiten[i].proStunde ?? 0) / max,
                    hoehe: 6,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('taetigkeit-name'),
            controller: _name,
            hint: 'Tätigkeit, z. B. Webseiten',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlasFeld(
                  key: const ValueKey('taetigkeit-euro'),
                  controller: _euro,
                  hint: '€ verdient',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlasFeld(
                  key: const ValueKey('taetigkeit-std'),
                  controller: _std,
                  hint: 'Stunden',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('taetigkeit-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              final n = _name.text.trim();
              final h = zahl(_std.text)?.toDouble();
              if (n.isEmpty || h == null || h <= 0) return;
              u.stand.setze(
                d.copyWith(
                  taetigkeiten: [
                    ...d.taetigkeiten,
                    Taetigkeit(
                      name: n,
                      euro: zahl(_euro.text)?.round() ?? 0,
                      stunden: h,
                    ),
                  ],
                ),
              );
              _name.clear();
              _euro.clear();
              _std.clear();
            },
          ),
        ],
      ),
      Block(
        art: GlasArt.gold,
        children: [
          CoachZeile(
            d.stundenSatz ??
                (besteTaetigkeit(d) == null
                    ? 'Sobald du zwei Tätigkeiten eingetragen hast, sage ich dir, worauf du dich konzentrierst.'
                    : 'Am meisten bringt dir ${besteTaetigkeit(d)!.name}.'),
          ),
          const SizedBox(height: 12),
          GlasKnopf(
            key: const ValueKey('stunde-coach'),
            label: busy
                ? 'Einen Moment …'
                : 'Worauf soll ich mich konzentrieren?',
            ghost: true,
            onTap: busy || d.taetigkeiten.length < 2
                ? null
                : () => warte(() async {
                    final s = await u.coach.stundenFokus(u.profile, u.kontext);
                    if (s == null) return offline();
                    await u.stand.setze(d.copyWith(stundenSatz: s));
                  }),
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Brainstorming

class BrainSeite extends StatefulWidget {
  const BrainSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<BrainSeite> createState() => _BrainSeiteState();
}

class _BrainSeiteState extends _Seite<BrainSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final kerne = [
      for (final g in d.gedanken)
        if (g.kern) g,
    ];
    final p = d.plan;
    return _spalte([
      Block(
        label: 'Einfach rein damit · ohne Ordnung',
        children: [
          GlasFeld(
            key: const ValueKey('brain-feld'),
            controller: _text,
            hint: 'Was geht dir gerade durch den Kopf?',
            zeilen: 3,
          ),
          const SizedBox(height: 10),
          GlasKnopf(
            key: const ValueKey('brain-ablegen'),
            label: 'Ablegen',
            onTap: () {
              final t = _text.text.trim();
              if (t.isEmpty) return;
              u.stand.setze(
                d.copyWith(
                  gedanken: [
                    ...d.gedanken,
                    Gedanke(text: t, zeit: u.jetzt()),
                  ],
                ),
              );
              _text.clear();
            },
          ),
        ],
      ),
      Block(
        label: 'Deine Gedanken-Ablage',
        rechts: '${d.gedanken.length} Gedanken',
        children: [
          if (d.gedanken.isEmpty)
            Text(
              'Noch leer. Alles, was du ablegst, landet hier.',
              style: Glas.tSoft,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = d.gedanken.length - 1; i >= 0; i--)
                  GlasChip(
                    key: ValueKey('gedanke-$i'),
                    label: d.gedanken[i].text.length > 40
                        ? '${d.gedanken[i].text.substring(0, 39)}…'
                        : d.gedanken[i].text,
                    an: d.gedanken[i].kern,
                    onTap: () {
                      final l = [...d.gedanken];
                      l[i] = l[i].umschalten();
                      u.stand.setze(d.copyWith(gedanken: l));
                    },
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            'Antippen macht einen Gedanken zur Kernidee (gold).',
            style: Glas.tSoft,
          ),
        ],
      ),
      if (kerne.isNotEmpty)
        Block(
          art: GlasArt.gold,
          label: 'Kernidee ausarbeiten',
          children: [
            _gross(kerne.last.text, size: 19),
            const SizedBox(height: 12),
            GlasKnopf(
              key: const ValueKey('brain-ausarbeiten'),
              label: busy ? 'Einen Moment …' : 'Mit dem Coach ausarbeiten',
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final r = await u.coach.ausarbeiten(
                        u.profile,
                        kerne.last.text,
                        [for (final g in d.gedanken) g.text],
                        u.kontext,
                      );
                      if (r == null) return offline();
                      await u.stand.setze(
                        d.copyWith(
                          plan: IdeenPlan(
                            idee: kerne.last.text,
                            ziel: r.ziel,
                            schritte: [for (final s in r.schritte) Punkt(s)],
                          ),
                        ),
                      );
                    }),
            ),
          ],
        ),
      if (p != null)
        Block(
          label: 'Ziel und Plan',
          rechts:
              '${p.schritte.where((s) => s.an).length} von ${p.schritte.length}',
          children: [
            Text(p.idee, style: Glas.tSoft),
            const SizedBox(height: 4),
            _gross(p.ziel, size: 18),
            const SizedBox(height: 6),
            for (var i = 0; i < p.schritte.length; i++)
              HakenZeile(
                key: ValueKey('plan-$i'),
                an: p.schritte[i].an,
                titel: p.schritte[i].text,
                onTap: () {
                  final s = [...p.schritte];
                  s[i] = s[i].umschalten(u.heute);
                  u.stand.setze(d.copyWith(plan: p.mitSchritten(s)));
                },
              ),
          ],
        ),
    ]);
  }
}

// ------------------------------------------------------------ Ideen-Prüfer

class PruefSeite extends StatefulWidget {
  const PruefSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<PruefSeite> createState() => _PruefSeiteState();
}

class _PruefSeiteState extends _Seite<PruefSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _idee = TextEditingController();
  final _antworten = <int, TextEditingController>{};

  @override
  void dispose() {
    _idee.dispose();
    for (final c in _antworten.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _a(int i, Frage f) => _antworten.putIfAbsent(
    i,
    () => TextEditingController(text: f.antwort ?? ''),
  );

  @override
  Widget inhalt(BuildContext context) {
    final p = d.pruefung;
    if (p == null) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Welche Idee willst du prüfen?',
          children: [
            GlasFeld(
              key: const ValueKey('pruef-idee'),
              controller: _idee,
              hint: 'z. B. Online-Kurs Logo-Design',
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('pruef-start'),
              label: busy ? 'Einen Moment …' : 'Harte Fragen stellen',
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final i = _idee.text.trim();
                      if (i.isEmpty) return;
                      final f =
                          await u.coach.pruefFragen(u.profile, i, u.kontext) ??
                          pruefFragen;
                      await u.stand.setze(
                        d.copyWith(
                          pruefung: IdeePruefung(
                            idee: i,
                            fragen: [for (final x in f) Frage(x)],
                          ),
                        ),
                      );
                      _idee.clear();
                    }),
            ),
          ],
        ),
      ]);
    }
    final r = p.reifeJetzt;
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Idee',
        rechts: '$r %',
        children: [
          _gross(p.idee, size: 20),
          const SizedBox(height: 10),
          GoldBalken(anteil: r / 100),
          const SizedBox(height: 6),
          Text('reif genug ab 80 %', style: Glas.tSoft),
        ],
      ),
      Block(
        label: 'Harte Fragen',
        children: [
          for (var i = 0; i < p.fragen.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        p.fragen[i].beantwortet
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 18,
                        color: p.fragen[i].beantwortet
                            ? CoachStyle.goldLight
                            : Glas.soft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.fragen[i].frage,
                          style: Glas.tText.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GlasFeld(
                    key: ValueKey('pruef-antwort-$i'),
                    controller: _a(i, p.fragen[i]),
                    hint: 'Deine ehrliche Antwort',
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('pruef-bewerten'),
            label: busy ? 'Einen Moment …' : 'Antworten prüfen lassen',
            onTap: busy
                ? null
                : () => warte(() async {
                    final f = [
                      for (var i = 0; i < p.fragen.length; i++)
                        Frage(
                          p.fragen[i].frage,
                          _a(i, p.fragen[i]).text.trim().isEmpty
                              ? null
                              : _a(i, p.fragen[i]).text.trim(),
                        ),
                    ];
                    var neu = p.copyWith(fragen: f);
                    await u.stand.setze(d.copyWith(pruefung: neu));
                    final ur = await u.coach.urteil(u.profile, neu);
                    if (ur == null) return offline();
                    neu = neu.copyWith(reife: ur.reife, satz: ur.satz);
                    await u.stand.setze(d.copyWith(pruefung: neu));
                  }),
          ),
        ],
      ),
      if (p.satz != null) Block(children: [CoachZeile(p.satz!)]),
      Center(
        child: TextButton(
          key: const ValueKey('pruef-neu'),
          onPressed: () {
            for (final c in _antworten.values) {
              c.dispose();
            }
            _antworten.clear();
            u.stand.setze(
              BusinessDaten.fromJson({...d.toJson()}..remove('pruefung')),
            );
          },
          child: Text('Andere Idee prüfen', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------ Gesprächs-Hilfe

class GespraechSeite extends StatefulWidget {
  const GespraechSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<GespraechSeite> createState() => _GespraechSeiteState();
}

class _GespraechSeiteState extends _Seite<GespraechSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _mit = TextEditingController();
  final _wann = TextEditingController();
  final _ziel = TextEditingController();
  bool _neu = false;

  @override
  void dispose() {
    _mit.dispose();
    _wann.dispose();
    _ziel.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final g = d.gespraech;
    if (g == null || _neu) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Vor dem Gespräch',
          children: [
            GlasFeld(
              key: const ValueKey('gespraech-mit'),
              controller: _mit,
              hint: 'Mit wem? z. B. Agentur Weber',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('gespraech-wann'),
              controller: _wann,
              hint: 'Wann? z. B. morgen 10:00',
            ),
            const SizedBox(height: 8),
            GlasFeld(
              key: const ValueKey('gespraech-ziel'),
              controller: _ziel,
              hint: 'Was willst du erreichen?',
              zeilen: 2,
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('gespraech-start'),
              label: busy ? 'Einen Moment …' : 'Leitfaden erstellen',
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final mit = _mit.text.trim();
                      final ziel = _ziel.text.trim();
                      if (mit.isEmpty || ziel.isEmpty) return;
                      final r = await u.coach.gespraech(
                        u.profile,
                        mit,
                        ziel,
                        u.kontext,
                      );
                      await u.stand.setze(
                        d.copyWith(
                          gespraech: Gespraech(
                            mit: mit,
                            ziel: ziel,
                            wann: _wann.text.trim().isEmpty
                                ? null
                                : _wann.text.trim(),
                            schritte:
                                r?.schritte ??
                                [
                                  for (final s in gespraechLeitfaden)
                                    Tipp(s.$1, s.$2),
                                ],
                            einwaende: r?.einwaende ?? const [],
                          ),
                        ),
                      );
                      setState(() => _neu = false);
                    }),
            ),
          ],
        ),
      ]);
    }
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: g.wann ?? 'Dein Gespräch',
        rechts: 'Leitfaden',
        children: [
          _gross(g.mit, size: 20),
          const SizedBox(height: 6),
          Text('Dein Ziel: ${g.ziel}', style: Glas.tSoft),
        ],
      ),
      Block(
        label: 'So läuft das Gespräch',
        children: [
          for (var k = 0; k < g.schritte.length; k++)
            _Nummer(
              n: k + 1,
              titel: g.schritte[k].titel,
              text: g.schritte[k].text,
              gold: k == 0,
            ),
        ],
      ),
      if (g.einwaende.isNotEmpty)
        Block(
          label: 'Wenn sie sagen …',
          children: [
            for (final e in g.einwaende)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GlasBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.sagt,
                        style: Glas.tText.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(e.antwort, style: Glas.tSoft),
                    ],
                  ),
                ),
              ),
          ],
        ),
      Center(
        child: TextButton(
          key: const ValueKey('gespraech-neu'),
          onPressed: () => setState(() => _neu = true),
          child: Text('Neues Gespräch vorbereiten', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------ Business-Baum

class BaumSeite extends StatefulWidget {
  const BaumSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<BaumSeite> createState() => _BaumSeiteState();
}

class _BaumSeiteState extends _Seite<BaumSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _dazu(String t) {
    if (t.trim().isEmpty) return;
    u.stand.setze(
      d.copyWith(
        meilensteine: [...d.meilensteine, Punkt(t.trim())],
        vorschlaege: [
          for (final v in d.vorschlaege)
            if (v != t) v,
        ],
      ),
    );
  }

  @override
  Widget inhalt(BuildContext context) {
    final n = naechsterAst(d);
    final anteil = n == null
        ? null
        : astAnteil(d.meilensteine[n].text, d, u.jetzt());
    return _spalte([
      Block(
        art: GlasArt.gold,
        children: [
          if (d.meilensteine.isEmpty)
            Text(
              'Noch kein Ast. Trag deinen ersten Meilenstein ein, z. B. „Erster Kunde“.',
              style: Glas.tSoft,
            )
          else
            BusinessBaum(meilensteine: d.meilensteine, gross: true),
        ],
      ),
      if (n != null)
        Block(
          label: 'Nächster Ast',
          rechts: anteil == null ? null : '${(anteil * 100).round()} %',
          children: [
            _gross(d.meilensteine[n].text, size: 19),
            if (anteil != null) ...[
              const SizedBox(height: 8),
              GoldBalken(anteil: anteil),
            ],
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('ast-erreicht'),
              label: 'Erreicht',
              onTap: () {
                final l = [...d.meilensteine];
                l[n] = l[n].umschalten(u.heute);
                u.stand.setze(d.copyWith(meilensteine: l));
                grossesHaken(context);
              },
            ),
          ],
        ),
      Block(
        label: 'Meilensteine',
        children: [
          for (var i = 0; i < d.meilensteine.length; i++)
            HakenZeile(
              key: ValueKey('ast-$i'),
              an: d.meilensteine[i].an,
              titel: d.meilensteine[i].text,
              onTap: () {
                final l = [...d.meilensteine];
                l[i] = l[i].umschalten(u.heute);
                u.stand.setze(d.copyWith(meilensteine: l));
              },
            ),
          const SizedBox(height: 8),
          GlasFeld(
            key: const ValueKey('ast-feld'),
            controller: _text,
            hint: 'Neuer Meilenstein',
          ),
          const SizedBox(height: 8),
          GlasKnopf(
            key: const ValueKey('ast-dazu'),
            label: 'Dazu',
            ghost: true,
            onTap: () {
              _dazu(_text.text);
              _text.clear();
            },
          ),
        ],
      ),
      Block(
        children: [
          const CoachZeile(
            'Jeder Meilenstein wird ein Ast. Neue schlage ich vor, wenn du einen erreicht hast.',
          ),
          if (d.vorschlaege.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in d.vorschlaege)
                  GlasChip(
                    key: ValueKey('vorschlag-$v'),
                    label: v,
                    an: false,
                    onTap: () => _dazu(v),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          GlasKnopf(
            key: const ValueKey('ast-vorschlag'),
            label: busy ? 'Einen Moment …' : 'Vorschläge vom Coach',
            ghost: true,
            onTap: busy
                ? null
                : () => warte(() async {
                    final l = await u.coach.meilensteine(u.profile, u.kontext);
                    if (l == null) return offline();
                    await u.stand.setze(d.copyWith(vorschlaege: l));
                  }),
          ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------------ Skill-Leiter

class SkillSeite extends StatefulWidget {
  const SkillSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  State<SkillSeite> createState() => _SkillSeiteState();
}

class _SkillSeiteState extends _Seite<SkillSeite> {
  @override
  BusinessUmfeld get u => widget.u;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget inhalt(BuildContext context) {
    final s = d.skill;
    if (s == null || s.stufen.isEmpty) {
      return _spalte([
        Block(
          art: GlasArt.gold,
          label: 'Welchen Skill willst du aufbauen?',
          children: [
            GlasFeld(
              key: const ValueKey('skill-feld'),
              controller: _name,
              hint: 'z. B. Verkaufen',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in const [
                  'Verkaufen',
                  'Verhandeln',
                  'Präsentieren',
                  'Führen',
                ])
                  GlasChip(
                    label: v,
                    an: _name.text == v,
                    onTap: () => setState(() => _name.text = v),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GlasKnopf(
              key: const ValueKey('skill-start'),
              label: busy ? 'Einen Moment …' : 'Leiter bauen',
              onTap: busy
                  ? null
                  : () => warte(() async {
                      final n = _name.text.trim();
                      if (n.isEmpty) return;
                      final l = await u.coach.skillStufen(
                        u.profile,
                        n,
                        u.kontext,
                      );
                      if (l == null) return offline();
                      await u.stand.setze(
                        d.copyWith(
                          skill: Skill(name: n, stufen: l),
                        ),
                      );
                    }),
            ),
          ],
        ),
      ]);
    }
    final next = s.naechste;
    return _spalte([
      Block(
        art: GlasArt.gold,
        label: 'Skill',
        rechts: '${s.erreicht} / ${s.stufen.length}',
        children: [
          _gross(s.name, size: 21),
          const SizedBox(height: 10),
          SkillLeiter(skill: s),
        ],
      ),
      if (next != null)
        Block(
          label: 'Stufe ${s.erreicht + 1} · diese Woche',
          children: [
            Text(
              next.text.isEmpty ? next.titel : next.text,
              style: Glas.tText.copyWith(fontSize: 14.5),
            ),
            const SizedBox(height: 12),
            GlasKnopf(
              key: const ValueKey('skill-weiter'),
              label: 'Stufe ${s.erreicht + 1} geschafft',
              onTap: () => u.stand.setze(d.copyWith(skill: s.weiter())),
            ),
          ],
        )
      else
        Block(
          art: GlasArt.gold,
          children: [
            CoachZeile(
              'Alle 7 Stufen geschafft. ${s.name} ist jetzt deine Stärke.',
            ),
          ],
        ),
      Center(
        child: TextButton(
          key: const ValueKey('skill-neu'),
          onPressed: () => u.stand.setze(
            BusinessDaten.fromJson({...d.toJson()}..remove('skill')),
          ),
          child: Text('Anderen Skill wählen', style: Glas.tSoft),
        ),
      ),
    ]);
  }
}

// ------------------------------------------------------------ Arbeit & Körper

/// "+28 %" more done on training days, null until there is enough.
int? trainingsPlus(ArbeitKoerper? k) {
  if (k == null || k.mit == null || k.ohne == null || k.ohne == 0) return null;
  return ((k.mit! / k.ohne! - 1) * 100).round();
}

class KoerperArbeitSeite extends StatelessWidget {
  const KoerperArbeitSeite({super.key, required this.u});
  final BusinessUmfeld u;

  @override
  Widget build(BuildContext context) {
    final k = u.koerper;
    final werte = [
      ('mit Training', k?.mit),
      ('ohne Training', k?.ohne),
      ('nach unter 7 h Schlaf', k?.kurz),
    ];
    final max = [for (final w in werte) ?w.$2]
        .fold<double>(1, (a, b) => b > a ? b : a);
    final plus = trainingsPlus(k);
    return _spalte([
      Block(
        label: 'Erledigte Arbeit pro Tag',
        children: [
          if (k == null || (k.mit == null && k.ohne == null))
            Text(
              'Kommt, sobald du ein paar Tage Fokus einträgst und dein Training im Check-in angibst.',
              style: Glas.tSoft,
            )
          else
            for (final (i, w) in werte.indexed)
              if (w.$2 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(w.$1, style: Glas.tSoft),
                      const SizedBox(height: 4),
                      i == 0
                          ? GoldBalken(anteil: w.$2! / max, hoehe: 10)
                          : _GrauBalken(anteil: w.$2! / max),
                    ],
                  ),
                ),
        ],
      ),
      Block(
        art: GlasArt.gold,
        children: [
          CoachZeile(
            plus == null
                ? 'Ich vergleiche deine Arbeit mit deinem Training und Schlaf, sobald genug Tage da sind.'
                : plus > 0
                ? 'An Trainingstagen schaffst du $plus Prozent mehr. Leg schwere Aufgaben auf Tage mit Training.'
                : 'An Trainingstagen schaffst du gerade nicht mehr. Vielleicht kostet das Training zur falschen Zeit Kraft.',
          ),
        ],
      ),
      Block(
        label: 'Zusammen mit Körper',
        children: [
          Text(
            'Training, Schlaf und Energie kommen aus deinem Körper-Bereich, die Arbeit aus Produktivität.',
            style: Glas.tSoft,
          ),
        ],
      ),
    ]);
  }
}

class _GrauBalken extends StatelessWidget {
  const _GrauBalken({required this.anteil});
  final double anteil;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: Container(
      height: 10,
      color: const Color(0x1AFFECC8),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: anteil.clamp(0, 1),
        child: Container(color: const Color(0x66CDBB98)),
      ),
    ),
  );
}
