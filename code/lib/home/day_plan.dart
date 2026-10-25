import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../feed/kcal.dart';
import '../planner/planner_data.dart';
import '../sleep/schlafzeiten.dart';
import '../ui/coach_style.dart';
import 'feed_widgets.dart';

/// The day plan on "Heute" (see Umsetzung/Tages-Planer.md): appointments
/// written in the user's own words, today's training from their plan,
/// meals and bedtime. Fitting training, meals and bedtime around the
/// appointments is the AI's job; until it is connected those rows say so.
class DayPlanCard extends StatelessWidget {
  const DayPlanCard({
    super.key,
    required this.today,
    required this.termine,
    required this.training,
    required this.mahlzeiten,
    required this.kcalZiel,
    required this.onAddTermin,
    required this.onRemoveTermin,
    required this.onSetMahlzeiten,
    this.onOpenTraining,
    this.foto,
    this.onOpenFoto,
    this.bettzeit,
    this.schlafStunden = 8,
    this.routineAb,
    this.onOpenSchlaf,
    this.aufstehen,
  });

  /// Today's wake-up time in minutes, null until set.
  final int? aufstehen;

  /// Tonight's bedtime, null until a wake-up time is set.
  final Bettzeit? bettzeit;
  final double schlafStunden;

  /// Time of the first step of the evening routine, e.g. "22:00".
  final String? routineAb;

  /// Opens the Schlaf page, where the wake-up times are set.
  final VoidCallback? onOpenSchlaf;

  final DateTime today;

  /// All appointments; the card picks today's and the coming week's.
  final List<Termin> termine;

  /// Today's entry of the user's training plan, empty on a day off.
  final String training;

  /// Meals per day, null until set.
  final int? mahlzeiten;

  /// Null until the kcal target is set up on the Ernährung page.
  final int? kcalZiel;

  final Future<void> Function(String text) onAddTermin;
  final Future<void> Function(Termin termin) onRemoveTermin;
  final Future<void> Function(int anzahl) onSetMahlzeiten;

  /// Opens the Training page, where exercises and the next target are.
  final VoidCallback? onOpenTraining;

  /// On the photo day (or its catch-up day) e.g. "Foto · Woche 7": a fixed
  /// morning slot that is never moved (see Umsetzung/Foto-Kit.md).
  final String? foto;
  final VoidCallback? onOpenFoto;

  Future<void> _pickMahlzeiten(BuildContext context) async {
    final n = await showDialog<int>(
      context: context,
      builder: (context) => _MahlzeitenDialog(current: mahlzeiten),
    );
    if (n != null) await onSetMahlzeiten(n);
  }

  @override
  Widget build(BuildContext context) {
    final heute = termineAm(termine, today);
    final start = DateTime(today.year, today.month, today.day);
    final demnaechst = [
      for (var i = 1; i <= 7; i++)
        ...termineAm(termine, start.add(Duration(days: i))),
    ];
    final meals = mahlzeiten;
    return FeedCard(
      title: 'Dein Tag',
      darkHead: true,
      icon: Icons.calendar_today_outlined,
      trailing: const Tag('passt sich an'),
      children: [
        _TerminField(onAdd: onAddTermin),
        const SizedBox(height: 12),
        _MealsLine(
          mahlzeiten: meals,
          kcalZiel: kcalZiel,
          onTap: () => _pickMahlzeiten(context),
        ),
        const SizedBox(height: 12),
        ..._zeitstrahl(heute, meals),
        if (demnaechst.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('NÄCHSTE TERMINE', style: CoachStyle.label),
          const SizedBox(height: 4),
          for (final t in demnaechst)
            _UpcomingRow(
              key: ObjectKey(t),
              termin: t,
              onRemove: () => onRemoveTermin(t),
            ),
        ],
      ],
    );
  }
}

extension on DayPlanCard {
  Widget _bettRow() {
    final b = bettzeit;
    if (b == null) {
      return _PlanRow(
        key: const ValueKey('tag-bettzeit'),
        zeit: '–',
        art: 'Schlaf',
        titel: 'Bettzeit',
        text: 'Trag ein, wann du aufstehst ›',
        last: true,
        onTap: onOpenSchlaf,
      );
    }
    final t = b.termin;
    final grund = t != null
        ? 'Morgen früh: ${t.text}. Darum schon um ${formatUhrzeit(b.aufstehen)} raus.'
        : 'Morgen um ${formatUhrzeit(b.aufstehen)} raus, '
              '${formatStunden(schlafStunden)} Std. Schlaf.';
    // Only when the routine starts before bedtime (same evening).
    final ab = parseUhrzeit(routineAb ?? '');
    final routine = ab != null && ab < b.bett && b.bett - ab <= 180
        ? '\nAbendroutine ab ${formatUhrzeit(ab)}.'
        : '';
    return _PlanRow(
      key: const ValueKey('tag-bettzeit'),
      zeit: formatUhrzeit(b.bett),
      art: 'Schlaf',
      titel: 'Bettzeit',
      text: '$grund$routine',
      last: true,
      onTap: onOpenSchlaf,
    );
  }
}

extension on DayPlanCard {
  /// Rows in time order with a glowing "Jetzt" line between done and next.
  /// Rows without a time (training and meals until the coach plans them)
  /// come after the timed ones, bedtime is always last.
  List<Widget> _zeitstrahl(List<Termin> heute, int? meals) {
    final jetzt = today.hour * 60 + today.minute;
    final zeilen = <(int?, Widget Function(bool vorbei))>[
      if (aufstehen != null)
        (
          aufstehen,
          (v) => _PlanRow(
            key: const ValueKey('tag-aufstehen'),
            zeit: formatUhrzeit(aufstehen!),
            art: 'Morgen',
            titel: 'Aufstehen',
            vorbei: v,
          ),
        ),
      if (foto != null)
        (
          aufstehen == null ? null : aufstehen! + 15,
          (v) => _PlanRow(
            key: const ValueKey('tag-foto'),
            zeit: 'früh',
            art: 'Foto',
            dark: true,
            titel: foto!,
            text: 'Mit dem Frame Kit 30 Sekunden.',
            onTap: onOpenFoto,
            vorbei: v,
          ),
        ),
      for (final t in heute)
        (
          parseUhrzeit(t.zeit ?? ''),
          (v) => _PlanRow(
            key: ObjectKey(t),
            zeit: t.zeit ?? '–',
            art: 'Termin',
            titel: t.text,
            onRemove: () => onRemoveTermin(t),
            vorbei: v,
          ),
        ),
    ];
    final mitZeit = [
      for (final z in zeilen)
        if (z.$1 != null) z,
    ]..sort((a, b) => a.$1!.compareTo(b.$1!));
    final ohneZeit = [
      for (final z in zeilen)
        if (z.$1 == null) z,
    ];
    final out = <Widget>[];
    var linie = false;
    void jetztLinie() {
      if (linie) return;
      linie = true;
      out.add(_JetztLinie(zeit: formatUhrzeit(jetzt)));
    }

    for (final (m, bau) in mitZeit) {
      final vorbei = m! <= jetzt;
      if (!vorbei) jetztLinie();
      out.add(bau(vorbei));
    }
    jetztLinie();
    for (final (_, bau) in ohneZeit) {
      out.add(bau(false));
    }
    out.add(
      _PlanRow(
        key: const ValueKey('tag-training'),
        zeit: '–',
        art: 'Training',
        dark: true,
        titel: training.trim().isEmpty ? 'Heute frei' : shortDay(training),
        text: training.trim().isEmpty ? null : 'Übungen in deinem Plan',
        onTap: onOpenTraining,
      ),
    );
    out.add(
      _PlanRow(
        zeit: '–',
        art: 'Essen',
        titel: meals == null ? 'Mahlzeiten' : '$meals Mahlzeiten',
      ),
    );
    out.add(_bettRow());
    return out;
  }
}

/// "JETZT 14:10" with a breathing gold dot and a fading line.
class _JetztLinie extends StatelessWidget {
  const _JetztLinie({required this.zeit});

  final String zeit;

  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('tag-jetzt'),
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0xFFFFF0C8), Color(0xFFE0BF7E), Color(0x00E0BF7E)],
              stops: [0, .5, 1],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'JETZT $zeit',
          style: CoachStyle.goldLabel.copyWith(
            color: const Color(0xFFF0C878),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0BF7E), Color(0x00E0BF7E)],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _TerminField extends StatefulWidget {
  const _TerminField({required this.onAdd});

  final Future<void> Function(String text) onAdd;

  @override
  State<_TerminField> createState() => _TerminFieldState();
}

class _TerminFieldState extends State<_TerminField> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    await widget.onAdd(text);
    _controller.clear();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('termin-feld'),
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: CoachStyle.body.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'z. B. Zahnarzt Do 17 Uhr',
              isDense: true,
              filled: true,
              fillColor: CoachStyle.page,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoachStyle.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoachStyle.line),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const ValueKey('termin-eintragen'),
          style: FilledButton.styleFrom(
            backgroundColor: CoachStyle.beige,
            foregroundColor: CoachStyle.goldInk,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          onPressed: _submit,
          child: const Text('Eintragen'),
        ),
      ],
    );
  }
}

/// "4 Mahlzeiten am Tag · kcal-Ziel 2.600", tap to change.
class _MealsLine extends StatelessWidget {
  const _MealsLine({
    required this.mahlzeiten,
    required this.kcalZiel,
    required this.onTap,
  });

  final int? mahlzeiten;
  final int? kcalZiel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final parts = [
      mahlzeiten == null
          ? 'Wie viele Mahlzeiten am Tag?'
          : '$mahlzeiten Mahlzeiten am Tag',
      if (kcalZiel != null) 'kcal-Ziel ${formatKcal(kcalZiel!)}',
    ];
    return Material(
      color: CoachStyle.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: const ValueKey('mahlzeiten'),
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  parts.join(' · '),
                  style: CoachStyle.body.copyWith(fontSize: 13.5),
                ),
              ),
              Text(
                mahlzeiten == null ? 'Festlegen' : 'Ändern',
                style: CoachStyle.goldLabel.copyWith(letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of the day plan: time, a small kind label, title and text.
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    super.key,
    required this.zeit,
    required this.art,
    required this.titel,
    this.text,
    this.dark = false,
    this.last = false,
    this.onRemove,
    this.onTap,
    this.vorbei = false,
  });

  /// Already over: dimmed with a tick.
  final bool vorbei;
  final String zeit;
  final String art;
  final String titel;
  final String? text;
  final bool dark;
  final bool last;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: CoachStyle.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              zeit,
              style: CoachStyle.cardTitle.copyWith(
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Kind(art, dark: dark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titel,
                        style: CoachStyle.body.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  HintText(text!),
                ],
              ],
            ),
          ),
          if (vorbei)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 2),
              child: Text('✓', style: TextStyle(color: CoachStyle.gold)),
            ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Termin löschen',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close,
                size: 18,
                color: CoachStyle.inkSoft,
              ),
              onPressed: onRemove,
            ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 2),
              child: Text(
                '›',
                style: TextStyle(color: CoachStyle.gold, fontSize: 20),
              ),
            ),
        ],
      ),
    );
    final sichtbar = vorbei ? Opacity(opacity: .5, child: row) : row;
    if (onTap == null) return sichtbar;
    return InkWell(onTap: onTap, child: sichtbar);
  }
}

class _Kind extends StatelessWidget {
  const _Kind(this.text, {this.dark = false});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: dark ? CoachStyle.beige : null,
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: dark ? CoachStyle.beige : CoachStyle.line),
    ),
    child: Text(
      text.toUpperCase(),
      style: CoachStyle.label.copyWith(
        fontSize: 10,
        letterSpacing: 0.8,
        color: dark ? CoachStyle.goldInk : CoachStyle.inkSoft,
      ),
    ),
  );
}

/// An appointment in the coming week, e.g. "Fr · 19:00 Geburtstag".
class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({super.key, required this.termin, required this.onRemove});

  final Termin termin;
  final VoidCallback onRemove;

  static const _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final d = termin.datum;
    final when =
        '${_days[d.weekday - 1]} ${d.day}.${d.month}.'
        '${termin.zeit == null ? '' : ' · ${termin.zeit}'}';
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(when, style: CoachStyle.body.copyWith(fontSize: 13.5)),
        ),
        Expanded(
          child: Text(
            termin.text,
            style: CoachStyle.body.copyWith(fontSize: 13.5),
          ),
        ),
        IconButton(
          tooltip: 'Termin löschen',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close, size: 16, color: CoachStyle.inkSoft),
          onPressed: onRemove,
        ),
      ],
    );
  }
}

class _MahlzeitenDialog extends StatelessWidget {
  const _MahlzeitenDialog({required this.current});

  final int? current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CoachStyle.card,
      title: const Text(
        'Wie viele Mahlzeiten willst du am Tag essen?',
        style: CoachStyle.cardTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HintText('Snacks zählen mit.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var n = 1; n <= 6; n++)
                ChoiceChip(
                  key: ValueKey('mahlzeiten-$n'),
                  label: Text('$n'),
                  selected: current == n,
                  selectedColor: CoachStyle.selectedFill,
                  onSelected: (_) => Navigator.pop(context, n),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
