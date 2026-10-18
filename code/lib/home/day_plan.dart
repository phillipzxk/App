import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../feed/kcal.dart';
import '../planner/planner_data.dart';
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
  });

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
        if (foto != null)
          _PlanRow(
            key: const ValueKey('tag-foto'),
            zeit: 'früh',
            art: 'Foto',
            dark: true,
            titel: foto!,
            text: 'Mit dem Frame Kit 30 Sekunden.',
            onTap: onOpenFoto,
          ),
        for (final t in heute)
          _PlanRow(
            key: ObjectKey(t),
            zeit: t.zeit ?? '–',
            art: 'Termin',
            titel: t.text,
            onRemove: () => onRemoveTermin(t),
          ),
        _PlanRow(
          zeit: '–',
          art: 'Training',
          dark: true,
          titel: training.trim().isEmpty ? 'Heute frei' : shortDay(training),
          text: training.trim().isEmpty ? null : 'Übungen in deinem Plan',
          onTap: onOpenTraining,
        ),
        _PlanRow(
          zeit: '–',
          art: 'Essen',
          titel: meals == null ? 'Mahlzeiten' : '$meals Mahlzeiten',
        ),
        const _PlanRow(
          zeit: '–',
          art: 'Schlaf',
          titel: 'Bettzeit',
          text: aiPending,
          last: true,
        ),
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
  });

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
    if (onTap == null) return row;
    return InkWell(
      key: const ValueKey('tag-training'),
      onTap: onTap,
      child: row,
    );
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
