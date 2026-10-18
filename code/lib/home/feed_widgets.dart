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

  /// "Heute": logo above, open on the dark page instead of a dark block.
  final bool brand;

  /// Symbol of the area, shown next to the title like on the cards.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final labelStyle = CoachStyle.goldLabel.copyWith(
      fontFamily: 'Sora',
      letterSpacing: 2.2,
      color: const Color(0xFFC9A25C),
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (brand) ...[
          const Row(
            children: [
              LogoMark(size: 26, ground: CoachStyle.cream),
              SizedBox(width: 6),
              Wordmark(fontSize: 11, ground: CoachStyle.cream),
            ],
          ),
          const SizedBox(height: 16),
        ],
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 6),
        Row(
          children: [
            if (icon case final i?) ...[
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CoachStyle.goldGradient,
                ),
                child: Icon(i, size: 20, color: CoachStyle.goldInk),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: GoldText(title, style: CoachStyle.title)),
          ],
        ),
      ],
    );
    {
      return Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 16),
            const GoldLine(),
            const SizedBox(height: 18),
          ],
        ),
      );
    }
  }
}

/// Fine gold line that fades out to both sides.
class GoldLine extends StatelessWidget {
  const GoldLine({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0x00C9A25C), Color(0xB3C9A25C), Color(0x00C9A25C)],
      ),
    ),
  );
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
    final night = NightScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: night ? CoachStyle.nightCard : null,
          gradient: night
              ? null
              : done
              ? CoachStyle.cardGradient
              : CoachStyle.reminderGradient,
          border: Border.all(
            color: night
                ? CoachStyle.hairline
                : done
                ? CoachStyle.edge
                : CoachStyle.goldEdge,
          ),
          boxShadow: night
              ? null
              : done
              ? CoachStyle.cardShadow
              : CoachStyle.goldShadow,
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
                      decoration: BoxDecoration(
                        color: done
                            ? (night ? CoachStyle.nightLine : CoachStyle.line)
                            : (night ? null : CoachStyle.gold),
                        gradient: !done && night
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFF5DFAE), Color(0xFF9A6D35)],
                              )
                            : null,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        child: Row(
                          children: [
                            SymbolBadge(icon, onDark: night),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: night
                                            ? const Color(0xFFF6EEDD)
                                            : null,
                                      ),
                                    ),
                                    TextSpan(text: ' · $text'),
                                  ],
                                ),
                                style: CoachStyle.body.copyWith(
                                  fontSize: 13.5,
                                  color: night ? CoachStyle.creamSoft : null,
                                ),
                              ),
                            ),
                            Text(
                              '›',
                              style: TextStyle(
                                color: night
                                    ? CoachStyle.goldBright
                                    : CoachStyle.gold,
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
    this.onGold = false,
  });

  final IconData icon;
  final double size;
  final bool onDark;

  /// On a gold background: dark circle with a gold symbol.
  final bool onGold;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: onGold ? CoachStyle.goldInk : null,
      gradient: onGold ? null : CoachStyle.goldGradient,
      shape: BoxShape.circle,
    ),
    child: Icon(
      icon,
      size: size * 0.53,
      color: onGold ? CoachStyle.goldLight : CoachStyle.goldInk,
    ),
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
    this.dark = false,
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

  /// Whole card dark, e.g. "Frag deinen Coach". On the dark "Heute" page
  /// every card is dark except the ones with a dark head (light contrast).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final night = dark || (NightScope.of(context) && !darkHead && !gold);
    final i = icon;
    final head = Row(
      children: [
        if (i != null) ...[
          SymbolBadge(i, onDark: darkHead || night, onGold: gold),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            title,
            style: gold
                ? CoachStyle.cardTitle.copyWith(color: CoachStyle.goldInk)
                : darkHead
                ? CoachStyle.cardTitle.copyWith(color: CoachStyle.goldBright)
                : night
                ? CoachStyle.cardTitle.copyWith(color: const Color(0xFFF6EEDD))
                : CoachStyle.cardTitle,
          ),
        ),
        ?trailing,
      ],
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gold)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(gradient: CoachStyle.goldGradient),
            child: head,
          )
        else if (darkHead)
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
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: CoachStyle.hairline)),
            ),
            child: head,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: NightScope(
            night: night,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    if (gold) {
      // The key card of an area page: metallic gold edge and gold head.
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: CoachStyle.goldGradient,
          borderRadius: BorderRadius.circular(19.5),
          boxShadow: CoachStyle.goldGlow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: ColoredBox(color: CoachStyle.cardBright, child: content),
        ),
      );
    }
    if (night) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF221B14), Color(0xFF16120E)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: CoachStyle.hairline),
          boxShadow: dark ? CoachStyle.darkShadow : null,
        ),
        child: content,
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: CoachStyle.cardBright,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? CoachStyle.goldEdge : CoachStyle.hairline,
        ),
        boxShadow: CoachStyle.cardShadowStrong,
      ),
      child: content,
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
            color: CoachStyle.beigeLabel,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x66D9C7A7), Color(0x00D9C7A7)],
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
    style: CoachStyle.body.copyWith(
      color: NightScope.of(context) ? CoachStyle.creamSoft : CoachStyle.inkSoft,
      fontSize: 13.5,
    ),
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
      color: CoachStyle.selectedFill,
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
      dark: true,
      children: [
        for (final f in widget.today) ...[
          Text(
            f.text,
            style: CoachStyle.body.copyWith(color: CoachStyle.cream),
          ),
          const SizedBox(height: 8),
          CoachNote(text: f.antwort.isNotEmpty ? f.antwort : aiPending),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          style: CoachStyle.body.copyWith(color: CoachStyle.cream),
          cursorColor: CoachStyle.goldBright,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: CoachStyle.body.copyWith(color: const Color(0xFF8F8270)),
            filled: true,
            fillColor: const Color(0x0DFFFFFF),
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: _border(CoachStyle.nightLineStrong),
            focusedBorder: _border(CoachStyle.goldBright),
          ),
        ),
        const SizedBox(height: 10),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => MainButton(
            label: 'Senden',
            gold: true,
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
      maxLines: multiline ? 10 : 1,
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
