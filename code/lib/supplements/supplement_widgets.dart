import 'package:flutter/material.dart';

import '../home/feed_widgets.dart';
import '../ui/coach_style.dart';
import 'supplement_data.dart';

/// The small reminder field on "Heute", shown always. Without a routine it
/// invites to set one up. Tapping it opens the Ernährung page.
class SupplementHinweis extends StatelessWidget {
  const SupplementHinweis({
    super.key,
    required this.supplements,
    required this.genommen,
    required this.now,
    required this.onTap,
  });

  final List<Supplement> supplements;
  final Set<String> genommen;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final offen = supplements.where((s) => !genommen.contains(s.id)).length;
    final next = naechsteOffene(supplements, genommen, now);
    final leer = supplements.isEmpty;
    final text = leer
        ? 'Routine festlegen'
        : next == null
        ? 'heute alles genommen'
        : '$offen offen, nächste ${next.zeit} ${next.name}';
    return HinweisFeld(
      key: const ValueKey('supp-hinweis'),
      icon: Icons.medication_outlined,
      title: 'Supplements',
      text: text,
      done: !leer && next == null,
      onTap: onTap,
    );
  }
}

/// The routine on the Ernährung page: set up, change, tick off.
class SupplementCard extends StatelessWidget {
  const SupplementCard({
    super.key,
    required this.supplements,
    required this.genommen,
    required this.onSave,
    required this.onToggle,
  });

  final List<Supplement> supplements;
  final Set<String> genommen;
  final Future<void> Function(List<Supplement> list) onSave;
  final Future<void> Function(Supplement s, bool genommen) onToggle;

  Future<void> _edit(BuildContext context) async {
    final result = await Navigator.of(context).push<List<Supplement>>(
      MaterialPageRoute(
        builder: (_) => SupplementEditor(supplements: supplements),
      ),
    );
    if (result != null) await onSave(result);
  }

  static const _arzt = HintText(
    'Du legst selbst fest, was du nimmst. Bei Fragen zu Mitteln oder '
    'Mengen: frag deinen Arzt.',
  );

  @override
  Widget build(BuildContext context) {
    if (supplements.isEmpty) {
      return FeedCard(
        title: 'Deine Supplement-Routine',
        icon: Icons.medication_outlined,
        gold: true,
        children: [
          const HintText(
            'Trag ein, was du wann nimmst. Die App erinnert dich daran, und '
            'du hakst es hier ab.',
          ),
          const SizedBox(height: 12),
          GhostButton(
            key: const ValueKey('supp-festlegen'),
            label: 'Routine festlegen',
            onPressed: () => _edit(context),
          ),
          const SizedBox(height: 10),
          _arzt,
        ],
      );
    }
    final list = nachZeit(supplements);
    final done = list.where((s) => genommen.contains(s.id)).length;
    return FeedCard(
      title: 'Deine Supplement-Routine',
      icon: Icons.medication_outlined,
      gold: true,
      trailing: Tag('heute $done von ${list.length}'),
      children: [
        for (var i = 0; i < list.length; i++)
          _Row(
            index: i,
            supplement: list[i],
            done: genommen.contains(list[i].id),
            first: i == 0,
            onToggle: onToggle,
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: GhostButton(
            key: const ValueKey('supp-aendern'),
            label: 'Routine ändern',
            onPressed: () => _edit(context),
          ),
        ),
        const SizedBox(height: 10),
        _arzt,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.index,
    required this.supplement,
    required this.done,
    required this.first,
    required this.onToggle,
  });

  final int index;
  final Supplement supplement;
  final bool done;
  final bool first;
  final Future<void> Function(Supplement s, bool genommen) onToggle;

  @override
  Widget build(BuildContext context) {
    final s = supplement;
    final strike = done
        ? const TextStyle(
            color: CoachStyle.inkSoft,
            decoration: TextDecoration.lineThrough,
            decorationColor: Color(0xFFBFB29A),
          )
        : const TextStyle();
    return InkWell(
      key: ValueKey('supp-check-$index'),
      onTap: () => onToggle(s, !done),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: first
              ? null
              : const Border(top: BorderSide(color: CoachStyle.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                s.zeit,
                style: CoachStyle.body
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 13.5)
                    .merge(strike),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: CoachStyle.body
                        .copyWith(fontWeight: FontWeight.w600)
                        .merge(strike),
                  ),
                  HintText(
                    s.menge.isEmpty ? 'täglich' : '${s.menge} · täglich',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? CoachStyle.gold : null,
                border: Border.all(color: CoachStyle.gold, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check, size: 15, color: CoachStyle.card)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rows of time, name and amount; rows without a name are dropped on save.
class SupplementEditor extends StatefulWidget {
  const SupplementEditor({super.key, required this.supplements});

  final List<Supplement> supplements;

  @override
  State<SupplementEditor> createState() => _SupplementEditorState();
}

typedef _Felder = (
  TextEditingController,
  TextEditingController,
  TextEditingController,
);

class _SupplementEditorState extends State<SupplementEditor> {
  late final List<_Felder> _rows = [
    for (final s in nachZeit(widget.supplements))
      (
        TextEditingController(text: s.zeit),
        TextEditingController(text: s.name),
        TextEditingController(text: s.menge),
      ),
    if (widget.supplements.isEmpty) _newRow(),
  ];
  bool _tried = false;

  _Felder _newRow() => (
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  );

  @override
  void dispose() {
    for (final (a, b, c) in _rows) {
      a.dispose();
      b.dispose();
      c.dispose();
    }
    super.dispose();
  }

  bool _zeitFehlt(_Felder r) =>
      r.$2.text.trim().isNotEmpty && normZeit(r.$1.text) == null;

  void _save() {
    if (_rows.any(_zeitFehlt)) {
      setState(() => _tried = true);
      return;
    }
    Navigator.of(context).pop([
      for (final (zeit, name, menge) in _rows)
        if (name.text.trim().isNotEmpty)
          Supplement(
            zeit: normZeit(zeit.text)!,
            name: name.text.trim(),
            menge: menge.text.trim(),
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return EditorPage(
      title: 'Deine Supplement-Routine',
      intro:
          'Was nimmst du, wie viel und um wie viel Uhr? Jede Einnahme gilt '
          'täglich, die App erinnert dich zur festen Uhrzeit.',
      onSave: _save,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: EditorField(
                    key: ValueKey('supp-zeit-$i'),
                    controller: _rows[i].$1,
                    hint: '08:00',
                    error: _tried && _zeitFehlt(_rows[i]) ? 'Uhrzeit?' : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EditorField(
                    key: ValueKey('supp-name-$i'),
                    controller: _rows[i].$2,
                    hint: 'Was?',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  child: EditorField(
                    key: ValueKey('supp-menge-$i'),
                    controller: _rows[i].$3,
                    hint: 'Menge',
                  ),
                ),
                IconButton(
                  tooltip: 'Einnahme entfernen',
                  icon: const Icon(Icons.close, color: CoachStyle.inkSoft),
                  onPressed: () => setState(() => _rows.removeAt(i)),
                ),
              ],
            ),
          ),
        GhostButton(
          key: const ValueKey('supp-hinzufuegen'),
          label: 'Einnahme hinzufügen',
          onPressed: () => setState(() => _rows.add(_newRow())),
        ),
        const SizedBox(height: 16),
        SupplementCard._arzt,
      ],
    );
  }
}
