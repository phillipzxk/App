import 'package:flutter/material.dart';

import '../feed/feed_data.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import '../ui/logo.dart';

/// Shown wherever the AI will write something once it is connected.
const aiPending = 'Kommt, sobald die KI angeschlossen ist.';

/// Head of a page in the Main Feed: fine golden rings in the corner, like
/// tree rings, and a gold ground line as in the logo. On "Heute" it also
/// carries the logo.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.label,
    required this.title,
    this.brand = false,
    this.icon,
  });

  final String label;
  final String title;
  final bool brand;

  /// Symbol of the area, shown next to the title like on the cards.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CoachStyle.gold, width: 2)),
      ),
      child: CustomPaint(
        painter: _RingsPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (brand) ...[
                const Row(
                  children: [
                    LogoMark(size: 26),
                    SizedBox(width: 6),
                    Wordmark(fontSize: 11),
                  ],
                ),
                const SizedBox(height: 14),
              ],
              Text(label.toUpperCase(), style: CoachStyle.label),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (icon case final i?) ...[
                    SymbolBadge(i, size: 36),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text(title, style: CoachStyle.title)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = CoachStyle.gold.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * 0.88, -size.height * 0.25);
    for (var r = 14.0; r < size.width * 0.7; r += 14) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small field on "Heute" that only shows the state of one function and
/// leads to its page on tap: gold edge, dark round symbol, arrow.
class HinweisFeld extends StatelessWidget {
  const HinweisFeld({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    this.done = false,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  /// Nothing open any more: calmer, without the gold glow.
  final bool done;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: done
              ? CoachStyle.cardGradient
              : CoachStyle.reminderGradient,
          border: Border.all(
            color: done ? CoachStyle.edge : CoachStyle.goldEdge,
          ),
          boxShadow: done ? CoachStyle.cardShadow : CoachStyle.goldShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      color: done ? CoachStyle.line : CoachStyle.gold,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        child: Row(
                          children: [
                            SymbolBadge(icon),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' · $text'),
                                  ],
                                ),
                                style: CoachStyle.body.copyWith(fontSize: 13.5),
                              ),
                            ),
                            const Text(
                              '›',
                              style: TextStyle(
                                color: CoachStyle.gold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark round symbol used on cards and fields, so each one is easy to tell
/// apart.
class SymbolBadge extends StatelessWidget {
  const SymbolBadge(
    this.icon, {
    super.key,
    this.size = 30,
    this.onDark = false,
  });

  final IconData icon;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onDark ? const Color(0xFF3A342B) : CoachStyle.dark,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: size * 0.53, color: CoachStyle.goldSoft),
  );
}

/// Rounded light card that holds one function of the feed: own symbol,
/// title, a fine line, then the content. [darkHead] gives the title a dark
/// bar, for the most important card of the day.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
    this.highlight = false,
    this.darkHead = false,
    this.gold = false,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Widget? trailing;
  final bool highlight;
  final bool darkHead;

  /// The key card of a page: gold gradient and gold edge like the fields
  /// on "Heute".
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final i = icon;
    final head = Row(
      children: [
        if (i != null) ...[
          SymbolBadge(i, onDark: darkHead),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: darkHead
                ? CoachStyle.cardTitle.copyWith(color: CoachStyle.goldSoft)
                : CoachStyle.cardTitle,
          ),
        ),
        ?trailing,
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (darkHead)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              gradient: CoachStyle.coachGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: head,
          )
        else
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: CoachStyle.line)),
            ),
            child: head,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: gold ? null : CoachStyle.cardBright,
        gradient: gold ? CoachStyle.goldCardGradient : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight || gold
              ? CoachStyle.goldEdge
              : CoachStyle.edgeStrong,
        ),
        boxShadow: gold ? CoachStyle.goldShadow : CoachStyle.cardShadowStrong,
      ),
      child: gold
          ? ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                children: [
                  content,
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: CoachStyle.gold),
                  ),
                ],
              ),
            )
          : content,
    );
  }
}

/// Small gold heading that splits "Heute" into groups.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 6, 0, 10),
    child: Row(
      children: [
        Text(
          text.toUpperCase(),
          style: CoachStyle.goldLabel.copyWith(
            fontFamily: 'Sora',
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [CoachStyle.goldEdge, Color(0x00E2CFA9)],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Small grey text for explanations inside a card.
class HintText extends StatelessWidget {
  const HintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: CoachStyle.body.copyWith(color: CoachStyle.inkSoft, fontSize: 13.5),
  );
}

/// Small pill, e.g. "passt sich an".
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF1E6D2),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      text,
      style: CoachStyle.goldLabel.copyWith(fontSize: 11, letterSpacing: 0),
    ),
  );
}

/// Outlined secondary button, e.g. "Plan bearbeiten".
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoachStyle.ink,
        side: const BorderSide(color: CoachStyle.line, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
        shape: const StadiumBorder(),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

/// Progress of one area over the last 14 days. The AI rates each area
/// from the daily check-in; until it is connected there are no values.
class AreaChart extends StatelessWidget {
  const AreaChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      title: 'Verlauf · letzte 14 Tage',
      icon: Icons.show_chart,
      children: [
        SizedBox(
          height: 48,
          child: CustomPaint(painter: _BaselinePainter(), size: Size.infinite),
        ),
        const SizedBox(height: 8),
        const HintText(
          'Dein Verlauf erscheint hier, sobald die KI deine Check-ins '
          'bewertet.',
        ),
      ],
    );
  }
}

class _BaselinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CoachStyle.bar
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Field to write to the coach about one area, with today's answers.
class AskCoachCard extends StatefulWidget {
  const AskCoachCard({
    super.key,
    required this.title,
    required this.hint,
    required this.today,
    required this.onSend,
  });

  final String title;
  final String hint;

  /// What the user already wrote today in this field.
  final List<CoachFrage> today;
  final Future<void> Function(String text) onSend;

  @override
  State<AskCoachCard> createState() => _AskCoachCardState();
}

class _AskCoachCardState extends State<AskCoachCard> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await widget.onSend(text);
    if (!mounted) return;
    _controller.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return FeedCard(
      title: widget.title,
      icon: Icons.chat_bubble_outline,
      darkHead: true,
      children: [
        for (final f in widget.today) ...[
          Text(f.text, style: CoachStyle.body),
          const SizedBox(height: 8),
          CoachNote(text: f.antwort.isNotEmpty ? f.antwort : aiPending),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          style: CoachStyle.body,
          cursorColor: CoachStyle.gold,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: _border(CoachStyle.line),
            focusedBorder: _border(CoachStyle.gold),
          ),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => MainButton(
            label: 'Senden',
            onPressed: _controller.text.trim().isEmpty || _sending
                ? null
                : _send,
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );
}

/// Full-screen editor page with a save button.
class EditorPage extends StatelessWidget {
  const EditorPage({
    super.key,
    required this.title,
    required this.intro,
    required this.children,
    required this.onSave,
  });

  final String title;
  final String intro;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return CoachPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Zurück',
              icon: const Icon(Icons.arrow_back, color: CoachStyle.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Text(title, style: CoachStyle.question),
                const SizedBox(height: 8),
                HintText(intro),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
          const SizedBox(height: 12),
          MainButton(label: 'Speichern', onPressed: onSave),
        ],
      ),
    );
  }
}

/// Text field for the editor pages.
class EditorField extends StatelessWidget {
  const EditorField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.suffix,
    this.error,
    this.number = false,
    this.multiline = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? suffix;
  final String? error;
  final bool number;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: CoachStyle.body,
      cursorColor: CoachStyle.gold,
      minLines: 1,
      maxLines: multiline ? 4 : 1,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: CoachStyle.inkSoft),
        floatingLabelStyle: const TextStyle(color: CoachStyle.gold),
        hintText: hint,
        hintStyle: CoachStyle.body.copyWith(color: CoachStyle.inkSoft),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: CoachStyle.inkSoft),
        errorText: error,
        filled: true,
        fillColor: CoachStyle.card,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CoachStyle.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CoachStyle.gold),
        ),
      ),
    );
  }
}
