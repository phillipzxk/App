import 'package:flutter/material.dart';

import '../checkin/checkin.dart';
import '../feed/durchgezogen.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'feed_widgets.dart';

const _wochentage = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
const _monate = [
  'JAN',
  'FEB',
  'MÄR',
  'APR',
  'MAI',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OKT',
  'NOV',
  'DEZ',
];

/// "13. BIS 19. OKT" for the week starting on [start].
String wochenTitel(DateTime start) {
  final ende = DateTime(start.year, start.month, start.day + 6);
  return start.month == ende.month
      ? '${start.day}. BIS ${ende.day}. ${_monate[ende.month - 1]}'
      : '${start.day}. ${_monate[start.month - 1]} BIS '
            '${ende.day}. ${_monate[ende.month - 1]}';
}

/// "Durchgezogen · diese Woche" on the Mindset page (vault
/// Umsetzung/Durchgezogen.md): this week's entries from the coach and the
/// user, a field to add one, and "Alle ansehen".
class DurchgezogenKarte extends StatefulWidget {
  const DurchgezogenKarte({
    super.key,
    required this.alle,
    required this.today,
    required this.onAdd,
    required this.onAlle,
  });

  final List<Durchgezogen> alle;
  final DateTime today;
  final Future<void> Function(String text) onAdd;
  final VoidCallback onAlle;

  @override
  State<DurchgezogenKarte> createState() => _DurchgezogenKarteState();
}

class _DurchgezogenKarteState extends State<DurchgezogenKarte> {
  final _controller = TextEditingController();
  bool _sendet = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _eintragen() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sendet) return;
    setState(() => _sendet = true);
    await widget.onAdd(text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _sendet = false);
  }

  @override
  Widget build(BuildContext context) {
    final woche = inWoche(widget.alle, widget.today);
    final t = widget.today;
    final letzte = inWoche(
      widget.alle,
      DateTime(t.year, t.month, t.day - 7),
    ).length;
    return Container(
      key: const ValueKey('durch-karte'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(1.3),
      decoration: BoxDecoration(
        gradient: CoachStyle.goldEdgeGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CoachStyle.nightShadow,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A2118), Color(0xFF1B1611)],
          ),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SymbolBadge(Icons.check, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DURCHGEZOGEN · DIESE WOCHE',
                    style: CoachStyle.goldLabel.copyWith(
                      color: CoachStyle.goldLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              key: const ValueKey('durch-anzahl'),
              TextSpan(
                children: [
                  TextSpan(
                    text: '${woche.length} Mal ',
                    style: CoachStyle.body.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5DFAE),
                    ),
                  ),
                  TextSpan(text: 'seit Montag · letzte Woche $letzte'),
                ],
              ),
              style: CoachStyle.body.copyWith(
                fontSize: 13,
                color: CoachStyle.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
            if (woche.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Noch nichts diese Woche. Nach deinem Check-in trägt der '
                  'Coach ein, was du trotz Unlust gemacht hast. Oder du '
                  'schreibst es selbst rein.',
                  style: CoachStyle.body.copyWith(
                    fontSize: 13.5,
                    color: CoachStyle.inkSoft,
                  ),
                ),
              ),
            for (var i = 0; i < woche.length; i++)
              DurchZeile(e: woche[i], ersteZeile: i == 0),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('durch-feld'),
                    controller: _controller,
                    style: CoachStyle.body.copyWith(color: CoachStyle.cream),
                    cursorColor: CoachStyle.goldBright,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _eintragen(),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Was hast du durchgezogen?',
                      hintStyle: CoachStyle.body.copyWith(
                        fontSize: 13.5,
                        color: const Color(0xFF8F8270),
                      ),
                      filled: true,
                      fillColor: const Color(0x0DFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      enabledBorder: _border(CoachStyle.nightLineStrong),
                      focusedBorder: _border(CoachStyle.goldBright),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final aus = _controller.text.trim().isEmpty || _sendet;
                    return FilledButton(
                      key: const ValueKey('durch-eintragen'),
                      onPressed: aus ? null : _eintragen,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE9DCC3),
                        foregroundColor: CoachStyle.goldInk,
                        disabledBackgroundColor: const Color(0xFF3A3026),
                        disabledForegroundColor: const Color(0xFF8F8270),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Eintragen',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('durch-alle'),
                onPressed: widget.onAlle,
                child: const Text(
                  'Alle ansehen ›',
                  style: TextStyle(
                    color: CoachStyle.goldLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );
}

/// One entry: weekday, text, COACH or DU, and an optional ✕.
class DurchZeile extends StatelessWidget {
  const DurchZeile({
    super.key,
    required this.e,
    this.ersteZeile = false,
    this.onDelete,
  });

  final Durchgezogen e;
  final bool ersteZeile;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: ersteZeile
            ? null
            : const Border(top: BorderSide(color: CoachStyle.nightLineStrong)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _wochentage[e.datum.weekday - 1],
                style: CoachStyle.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: CoachStyle.inkSoft,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              e.text,
              style: CoachStyle.body.copyWith(
                fontSize: 14.5,
                color: const Color(0xFFF6EEDD),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: e.vonCoach ? const Color(0x1FD4A85E) : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: e.vonCoach ? CoachStyle.goldEdge : CoachStyle.line,
              ),
            ),
            child: Text(
              e.vonCoach ? 'COACH' : 'DU',
              style: CoachStyle.body.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: e.vonCoach
                    ? CoachStyle.goldLight
                    : CoachStyle.beigeLabel,
              ),
            ),
          ),
          if (onDelete != null)
            SizedBox(
              width: 34,
              height: 24,
              child: IconButton(
                tooltip: 'Löschen',
                padding: EdgeInsets.zero,
                iconSize: 18,
                onPressed: onDelete,
                icon: const Icon(Icons.close, color: CoachStyle.inkSoft),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Alle ansehen": everything since the start, grouped by week, each entry
/// can be deleted with ✕.
class DurchgezogenSeite extends StatefulWidget {
  const DurchgezogenSeite({
    super.key,
    required this.alle,
    required this.today,
    required this.onDelete,
  });

  final List<Durchgezogen> alle;
  final DateTime today;
  final Future<void> Function(Durchgezogen e) onDelete;

  @override
  State<DurchgezogenSeite> createState() => _DurchgezogenSeiteState();
}

class _DurchgezogenSeiteState extends State<DurchgezogenSeite> {
  late List<Durchgezogen> _alle = List.of(widget.alle);

  Future<void> _loeschen(Durchgezogen e) async {
    setState(
      () => _alle = [
        for (final x in _alle)
          if (!identical(x, e)) x,
      ],
    );
    await widget.onDelete(e);
  }

  @override
  Widget build(BuildContext context) {
    final diese = dayKey(wochenStart(widget.today));
    final wochen = nachWochen(_alle);
    return Scaffold(
      backgroundColor: CoachStyle.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: CoachStyle.goldLight,
        elevation: 0,
      ),
      body: NightScope(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            const PageHeader(label: 'Seit deinem Start', title: 'Durchgezogen'),
            Text(
              _alle.isEmpty
                  ? 'Hier sammelt sich alles, was du trotz Unlust gemacht '
                        'hast. Noch ist nichts eingetragen.'
                  : 'Alles, was du trotz Unlust gemacht hast, seit deinem '
                        'Start. Mit ✕ löschst du einen Eintrag.',
              style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
            ),
            const SizedBox(height: 16),
            for (final (start, eintraege) in wochen) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dayKey(start) == diese
                            ? 'DIESE WOCHE'
                            : wochenTitel(start),
                        style: CoachStyle.goldLabel.copyWith(
                          color: CoachStyle.beigeLabel,
                        ),
                      ),
                    ),
                    Text(
                      '${eintraege.length} MAL',
                      style: CoachStyle.goldLabel.copyWith(
                        color: CoachStyle.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: CoachStyle.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CoachStyle.line),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < eintraege.length; i++)
                      DurchZeile(
                        key: ValueKey('durch-zeile-${eintraege[i].erstellt}'),
                        e: eintraege[i],
                        ersteZeile: i == 0,
                        onDelete: () => _loeschen(eintraege[i]),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
