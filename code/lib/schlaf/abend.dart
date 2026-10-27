import 'dart:async';

import 'package:flutter/material.dart';

import '../sleep/schlafzeiten.dart';
import '../training/training_widgets.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'aufwachen.dart';
import 'schlaf_data.dart';
import 'schlaf_logik.dart';
import 'schlaf_widgets.dart';

InputDecoration _feld(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: tSoft,
  isDense: true,
  filled: true,
  fillColor: const Color(0xCC1A140E),
  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF3A3550)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CoachStyle.goldLight),
  ),
);

/// When the alarm rings next: tomorrow at the alarm time, or today when it
/// is still night.
DateTime naechsterWecker(DateTime jetzt, int minute) {
  var tag = DateTime(jetzt.year, jetzt.month, jetzt.day);
  final w = tag.add(Duration(minutes: minute));
  if (!w.isAfter(jetzt)) tag = tag.add(const Duration(days: 1));
  return tag.add(Duration(minutes: minute));
}

/// "Dein Abend": 3 things you are grateful for and 3 you do better
/// tomorrow. "Gute Nacht" only when all 6 are filled, then Runterfahren.
class AbendSeite extends StatefulWidget {
  const AbendSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<AbendSeite> createState() => _AbendSeiteState();
}

class _AbendSeiteState extends State<AbendSeite> {
  SchlafUmfeld get u => widget.umfeld;
  late final Journal? _alt = u.d.journalAm(u.heute);
  late final _dankbar = [
    for (var i = 0; i < 3; i++)
      TextEditingController(
        text: (_alt?.dankbar.length ?? 0) > i ? _alt!.dankbar[i] : '',
      ),
  ];
  late final _besser = [
    for (var i = 0; i < 3; i++)
      TextEditingController(
        text: (_alt?.besser.length ?? 0) > i ? _alt!.besser[i] : '',
      ),
  ];

  @override
  void dispose() {
    for (final c in [..._dankbar, ..._besser]) {
      c.dispose();
    }
    super.dispose();
  }

  Journal get _journal => Journal(
    tag: u.heute,
    dankbar: [for (final c in _dankbar) c.text.trim()],
    besser: [for (final c in _besser) c.text.trim()],
    guteNacht: _alt?.guteNacht,
  );

  Future<void> _guteNacht() async {
    final j = _journal;
    await u.stand.setze(
      u.d.mitJournal(
        Journal(
          tag: j.tag,
          dankbar: j.dankbar,
          besser: j.besser,
          guteNacht: u.jetzt(),
        ),
      ),
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RunterfahrenSeite(umfeld: u)),
    );
  }

  /// Saves what is typed so far, without Gute Nacht.
  Future<void> _merken() async {
    final j = _journal;
    if ([...j.dankbar, ...j.besser].every((x) => x.isEmpty)) return;
    await u.stand.setze(u.d.mitJournal(j));
  }

  @override
  Widget build(BuildContext context) {
    final fertig = _journal.fertig;
    final j = u.jetzt();
    return PopScope(
      onPopInvokedWithResult: (_, _) => _merken(),
      child: SchlafSeite(
        umfeld: u,
        phase: HimmelPhase.abend,
        label: '${germanWeekday(j)} · ${formatUhrzeit(j.hour * 60 + j.minute)}',
        titel: 'Dein Abend',
        bau: (context) => [
          const TKarte(
            child: CoachZeile(
              text: 'Bevor du runterfährst: kurz den Tag abschließen.',
            ),
          ),
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TLabel('3 Sachen, für die du heute dankbar bist'),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      key: ValueKey('dankbar-$i'),
                      controller: _dankbar[i],
                      style: tText,
                      decoration: _feld('${i + 1}.'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
          TKarte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TLabel('3 Sachen, die du morgen besser machst'),
                const SizedBox(height: 8),
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      key: ValueKey('besser-$i'),
                      controller: _besser[i],
                      style: tText,
                      decoration: _feld('${i + 1}.'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                const Text(
                  'Morgen früh bekommst du sie in „Dein Tag“ zurück.',
                  style: tSoft,
                ),
              ],
            ),
          ),
          MainButton(
            key: const ValueKey('gute-nacht'),
            label: 'Gute Nacht',
            onPressed: fertig ? _guteNacht : null,
          ),
          const SizedBox(height: 6),
          Text(
            fertig
                ? 'Danach wird alles dunkel bis zu deinem Wecker.'
                : 'Erst alle 6 Felder, dann geht Gute Nacht.',
            key: const ValueKey('gute-nacht-hinweis'),
            textAlign: TextAlign.center,
            style: tSoft,
          ),
        ],
      ),
    );
  }
}

/// Runterfahren: dark screen, the evening routine step by step, darker
/// with every step. At the end the app goes to rest until the alarm.
class RunterfahrenSeite extends StatefulWidget {
  const RunterfahrenSeite({super.key, required this.umfeld});
  final SchlafUmfeld umfeld;

  @override
  State<RunterfahrenSeite> createState() => _RunterfahrenSeiteState();
}

class _RunterfahrenSeiteState extends State<RunterfahrenSeite> {
  SchlafUmfeld get u => widget.umfeld;
  int _schritt = 0;

  List<(String, String)> get _schritte => u.routine.isNotEmpty
      ? u.routine
      : const [
          ('', 'Handy weg, Licht runter'),
          ('', 'Zähne, kurz lüften'),
          ('', 'Licht aus'),
        ];

  Future<void> _schlafen() async {
    final j = u.jetzt();
    final wecker = naechsterWecker(j, u.weckzeit ?? u.aufstehen);
    final alt = u.d.journalAm(u.heute);
    var d = u.d.copyWith(ruheBis: wecker);
    if (alt != null) {
      d = d.mitJournal(
        Journal(
          tag: alt.tag,
          dankbar: alt.dankbar,
          besser: alt.besser,
          guteNacht: j,
        ),
      );
    }
    await u.stand.setze(d);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final s = _schritte;
    final dunkel = 1 - (_schritt / s.length) * .8;
    final letzter = _schritt >= s.length - 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        color: Color.fromARGB(
          255,
          (26 * dunkel).round(),
          (20 * dunkel).round(),
          (14 * dunkel).round(),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'RUNTERFAHREN',
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 1.8,
                      color: Color(0xFF6B5535),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i <= _schritt && i < s.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        s[i].$1.isEmpty ? s[i].$2 : '${s[i].$1} · ${s[i].$2}',
                        key: ValueKey('runter-$i'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                          fontSize: i == _schritt ? 17 : 13,
                          color: i == _schritt
                              ? const Color(0xFFCDBB98)
                              : const Color(0xFF4A3B2A),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    child: OutlinedButton(
                      key: const ValueKey('runter-weiter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8F8068),
                        side: const BorderSide(color: Color(0xFF4A3B2A)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: letzter
                          ? _schlafen
                          : () => setState(() => _schritt++),
                      child: Text(letzter ? 'Schlafen' : 'Erledigt'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rest mode: all dark, the monkey asleep, until the alarm. When the
/// alarm time comes while the app is open, the alarm screen opens.
class RuheSchirm extends StatefulWidget {
  const RuheSchirm({super.key, required this.umfeld, required this.bis});
  final SchlafUmfeld umfeld;
  final DateTime bis;

  @override
  State<RuheSchirm> createState() => _RuheSchirmState();
}

class _RuheSchirmState extends State<RuheSchirm> {
  Timer? _t;
  SchlafUmfeld get u => widget.umfeld;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!u.jetzt().isBefore(widget.bis)) _wecken();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _aus() => u.stand.setze(u.d.copyWith(ruheAus: true));

  Future<void> _wecken() async {
    _t?.cancel();
    final nav = Navigator.of(context);
    await _aus();
    await nav.push(
      MaterialPageRoute<void>(builder: (_) => WeckerKlingelt(umfeld: u)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = u.d.wecker;
    final m = widget.bis.hour * 60 + widget.bis.minute;
    return Material(
      key: const ValueKey('ruhe'),
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SchlafAffe(),
              const SizedBox(height: 14),
              Text(
                'Gute Nacht${u.profile.name.isEmpty ? '' : ', ${u.profile.name}'}.',
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF4A3B2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Wecker ${formatUhrzeit(m)}'
                '${w.sonne ? ' · Sonnenaufgang ab ${formatUhrzeit((m - 10) % 1440)}' : ''}',
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 12,
                  color: Color(0xFF3A2F24),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Ruhezustand bis zum Wecker',
                style: TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 11,
                  color: Color(0xFF2A221A),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const ValueKey('ruhe-aus'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3A2F24),
                ),
                onPressed: _aus,
                child: const Text('Doch noch wach'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The coach asleep: dimmed, eyes closed by the dark, slow z's rising.
class _SchlafAffe extends StatefulWidget {
  const _SchlafAffe();

  @override
  State<_SchlafAffe> createState() => _SchlafAffeState();
}

class _SchlafAffeState extends State<_SchlafAffe>
    with SingleTickerProviderStateMixin {
  late final _a = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    height: 100,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 20,
          top: 20,
          child: Opacity(
            opacity: .35,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(Color(0xFF1A1430), BlendMode.color),
              child: CoachAvatar(size: 72),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _a,
          builder: (_, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < 2; i++)
                Builder(
                  builder: (_) {
                    final t = (_a.value + i * .5) % 1;
                    return Positioned(
                      left: 84 + t * 14,
                      top: 18 - t * 26,
                      child: Opacity(
                        opacity: (1 - t) * .6,
                        child: Text(
                          'z',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 12 + t * 8,
                            color: const Color(0xFF6B5535),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
