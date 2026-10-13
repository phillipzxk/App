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
  });

  final String label;
  final String title;
  final bool brand;

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
              Text(title, style: CoachStyle.title),
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

/// Rounded light card that holds one function of the feed.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.highlight = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoachStyle.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? const Color(0xFFE2CFA9) : CoachStyle.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: CoachStyle.cardTitle)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
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
