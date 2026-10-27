import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'training_data.dart';

/// Dark card with a fine gold edge, like the draft (Entwurf 2).
class TKarte extends StatelessWidget {
  const TKarte({
    super.key,
    required this.child,
    this.gold = false,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;

  /// Highlighted: stronger gold edge and glow.
  final bool gold;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(1.2),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: gold
          ? CoachStyle.goldGradient
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x88E0BF7E), Color(0x335A4630), Color(0x55E0BF7E)],
            ),
      boxShadow: gold ? CoachStyle.goldGlow : null,
    ),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF261C12), Color(0xFF140F0A)],
        ),
      ),
      child: child,
    ),
  );
}

/// Small gold heading inside a card, e.g. "DEINE TAGESFORM".
class TLabel extends StatelessWidget {
  const TLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'Sora',
      fontWeight: FontWeight.w600,
      fontSize: 10,
      letterSpacing: 1.8,
      color: Color(0xFFC9A25C),
    ),
  );
}

/// The coach's face with a short text next to it.
class CoachZeile extends StatelessWidget {
  const CoachZeile({super.key, required this.text, this.label, this.unten});

  final String text;
  final String? label;

  /// E.g. "Rückgängig" under the text.
  final Widget? unten;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CoachAvatar(size: 32),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) ...[TLabel(label!), const SizedBox(height: 3)],
            Text(text, style: tText),
            if (unten != null) ...[const SizedBox(height: 4), unten!],
          ],
        ),
      ),
    ],
  );
}

const tText = TextStyle(
  fontFamily: 'Figtree',
  fontSize: 13.5,
  height: 1.45,
  color: CoachStyle.ink,
);

const tSoft = TextStyle(
  fontFamily: 'Figtree',
  fontSize: 12,
  height: 1.4,
  color: CoachStyle.beigeLabel,
);

const tTitel = TextStyle(
  fontFamily: 'Sora',
  fontWeight: FontWeight.w600,
  fontSize: 15,
  color: CoachStyle.ink,
);

/// A tappable gold text, e.g. "Rückgängig", "+ Satz".
class TLink extends StatelessWidget {
  const TLink(this.text, {super.key, required this.onTap, this.soft = false});

  final String text;
  final VoidCallback? onTap;
  final bool soft;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
          color: soft ? CoachStyle.inkSoft : CoachStyle.goldLight,
        ),
      ),
    ),
  );
}

/// A pill to pick, gold when chosen.
class TChip extends StatelessWidget {
  const TChip(
    this.text, {
    super.key,
    required this.an,
    required this.onTap,
    this.klein = false,
  });

  final String text;
  final bool an;
  final VoidCallback? onTap;
  final bool klein;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
        horizontal: klein ? 9 : 12,
        vertical: klein ? 5 : 7,
      ),
      decoration: BoxDecoration(
        gradient: an ? CoachStyle.goldGradient : null,
        color: an ? null : const Color(0xFF1A140E),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: an ? Colors.transparent : const Color(0xFF4A3B2A),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.w600,
          fontSize: klein ? 11.5 : 12.5,
          color: an ? CoachStyle.goldInk : CoachStyle.beigeLabel,
        ),
      ),
    ),
  );
}

/// Outlined full-width button.
class TGhost extends StatelessWidget {
  const TGhost(this.text, {super.key, required this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: CoachStyle.beigeLabel,
        side: const BorderSide(color: CoachStyle.goldEdge),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Sora',
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      child: Text(text),
    ),
  );
}

/// Round tick for one set.
class TTick extends StatelessWidget {
  const TTick({super.key, required this.an, required this.onTap});
  final bool an;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: an ? 'Satz abgehakt' : 'Satz abhaken',
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: an ? CoachStyle.goldGradient : null,
          border: an
              ? null
              : Border.all(color: CoachStyle.goldEdge, width: 1.4),
        ),
        child: Icon(
          Icons.check,
          size: 18,
          color: an ? CoachStyle.goldInk : CoachStyle.goldLight,
        ),
      ),
    ),
  );
}

/// Number field that keeps its text while typing and shows new values
/// from outside when it is not focused.
class ZahlFeld extends StatefulWidget {
  const ZahlFeld({
    super.key,
    required this.wert,
    required this.onChanged,
    this.einheit,
    this.dezimal = true,
    this.gedimmt = false,
    this.enabled = true,
  });

  final double? wert;
  final ValueChanged<double?> onChanged;
  final String? einheit;
  final bool dezimal;
  final bool gedimmt;
  final bool enabled;

  @override
  State<ZahlFeld> createState() => _ZahlFeldState();
}

class _ZahlFeldState extends State<ZahlFeld> {
  late final _c = TextEditingController(text: _text(widget.wert));
  final _focus = FocusNode();

  static String _text(double? v) => v == null ? '' : zahl(v);

  @override
  void didUpdateWidget(ZahlFeld old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.wert != old.wert) {
      _c.text = _text(widget.wert);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _c,
        focusNode: _focus,
        enabled: widget.enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.numberWithOptions(decimal: widget.dezimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        style: TextStyle(
          fontFamily: 'Figtree',
          fontWeight: widget.gedimmt ? FontWeight.w500 : FontWeight.w600,
          fontSize: 14.5,
          color: widget.gedimmt ? CoachStyle.inkSoft : CoachStyle.ink,
        ),
        cursorColor: CoachStyle.goldLight,
        decoration: InputDecoration(
          isDense: true,
          hintText: '–',
          hintStyle: const TextStyle(color: CoachStyle.inkSoft),
          filled: true,
          fillColor: const Color(0xFF1A140E),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 9,
            horizontal: 6,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4A3B2A)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E261C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: CoachStyle.goldLight,
              width: 1.5,
            ),
          ),
        ),
        onChanged: (t) =>
            widget.onChanged(double.tryParse(t.replaceAll(',', '.'))),
      ),
      if (widget.einheit != null) ...[
        const SizedBox(height: 2),
        Text(widget.einheit!, style: tSoft.copyWith(fontSize: 10)),
      ],
    ],
  );
}

/// −/+ with the number in the middle, for the plan settings.
class TStepper extends StatelessWidget {
  const TStepper({
    super.key,
    required this.wert,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int wert, min, max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget knopf(String t, int d) => InkWell(
      onTap: (wert + d < min || wert + d > max)
          ? null
          : () => onChanged(wert + d),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CoachStyle.goldEdge),
        ),
        child: Text(
          t,
          style: const TextStyle(color: CoachStyle.goldLight, fontSize: 16),
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        knopf('−', -1),
        SizedBox(
          width: 34,
          child: Text(
            '$wert',
            textAlign: TextAlign.center,
            style: tTitel.copyWith(fontSize: 14),
          ),
        ),
        knopf('+', 1),
      ],
    );
  }
}

/// The gold sprout that grows for a new record (idea 2), with sparks.
class RekordSpross extends StatefulWidget {
  const RekordSpross({super.key, this.size = 76});
  final double size;

  @override
  State<RekordSpross> createState() => _RekordSprossState();
}

class _RekordSprossState extends State<RekordSpross>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size * 2,
    height: widget.size,
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(painter: _SprossMaler(_c.value)),
    ),
  );
}

class _SprossMaler extends CustomPainter {
  _SprossMaler(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, h = size.height;
    final stiel = Curves.easeOut.transform((t * 1.6).clamp(0, 1));
    final blatt = Curves.elasticOut.transform(((t - 0.25) * 1.5).clamp(0, 1));
    final p = Paint()
      ..color = CoachStyle.gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx, h - 4),
      Offset(cx, h - 4 - (h * 0.5) * stiel),
      p,
    );
    void zeichneBlatt(double richtung, double y, Color c) {
      canvas.save();
      canvas.translate(cx, y);
      canvas.scale(blatt * richtung, blatt);
      final path = Path()
        ..moveTo(0, 0)
        ..cubicTo(
          -h * 0.05,
          -h * 0.28,
          -h * 0.25,
          -h * 0.34,
          -h * 0.32,
          -h * 0.3,
        )
        ..cubicTo(-h * 0.3, -h * 0.12, -h * 0.16, 0, 0, 0);
      canvas.drawPath(path, Paint()..color = c);
      canvas.restore();
    }

    zeichneBlatt(1, h * 0.62, CoachStyle.goldLight);
    zeichneBlatt(-1, h * 0.5, const Color(0xFFF5DFAE));
    // Sparks fly out and fade.
    final f = ((t - 0.2) / 0.8).clamp(0.0, 1.0);
    if (f > 0 && f < 1) {
      final r = math.Random(7);
      for (var i = 0; i < 14; i++) {
        final a = r.nextDouble() * math.pi * 2;
        final d = (30 + r.nextDouble() * 40) * f;
        canvas.drawCircle(
          Offset(cx + math.cos(a) * d, h * 0.45 + math.sin(a) * d * 0.7),
          2.2,
          Paint()..color = const Color(0xFFFFF0C8).withValues(alpha: 1 - f),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SprossMaler old) => old.t != t;
}

/// The rest ring of the Trainings-Modus (idea 9).
class PausenRing extends StatelessWidget {
  const PausenRing({super.key, required this.rest, required this.gesamt});
  final int rest, gesamt;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 180,
    height: 180,
    child: CustomPaint(
      painter: _RingMaler(gesamt == 0 ? 0 : rest / gesamt),
      child: Center(
        child: Text(
          mmss(rest),
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 36,
            color: Color(0xFFF5DFAE),
          ),
        ),
      ),
    ),
  );
}

class _RingMaler extends CustomPainter {
  _RingMaler(this.anteil);
  final double anteil;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = CoachStyle.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * anteil,
      false,
      Paint()
        ..color = CoachStyle.goldLight
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(_RingMaler old) => old.anteil != anteil;
}

/// A line chart of weekly values, gold, with the newest point bright.
class WochenKurve extends StatelessWidget {
  const WochenKurve({super.key, required this.werte, this.hoeher = true});

  /// One value per week, oldest first; null = no session that week.
  final List<double?> werte;

  /// False when lower is better (pace); the axis is turned.
  final bool hoeher;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 150,
    child: CustomPaint(
      size: Size.infinite,
      painter: _KurveMaler(werte, hoeher),
    ),
  );
}

class _KurveMaler extends CustomPainter {
  _KurveMaler(this.werte, this.hoeher);
  final List<double?> werte;
  final bool hoeher;

  @override
  void paint(Canvas canvas, Size size) {
    final da = [for (final w in werte) ?w];
    if (da.isEmpty) return;
    var lo = da.reduce(math.min), hi = da.reduce(math.max);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    const links = 30.0, unten = 22.0, oben = 10.0;
    final w = size.width - links - 8;
    final h = size.height - unten - oben;
    double x(int i) =>
        links + (werte.length == 1 ? w / 2 : i * w / (werte.length - 1));
    double y(double v) {
      final a = (v - lo) / (hi - lo);
      return oben + h * (hoeher ? 1 - a : a);
    }

    final linie = Paint()..color = CoachStyle.edge;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final v in [lo, (lo + hi) / 2, hi]) {
      canvas.drawLine(Offset(links - 4, y(v)), Offset(size.width, y(v)), linie);
      tp.text = TextSpan(
        text: zahl((v * 2).round() / 2),
        style: tSoft.copyWith(fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y(v) - 7));
    }
    final pfad = Path();
    var erster = true;
    for (var i = 0; i < werte.length; i++) {
      final v = werte[i];
      if (v == null) continue;
      if (erster) {
        pfad.moveTo(x(i), y(v));
        erster = false;
      } else {
        pfad.lineTo(x(i), y(v));
      }
    }
    canvas.drawPath(
      pfad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = const LinearGradient(
          colors: [Color(0xFF9A6D35), Color(0xFFF5DFAE)],
        ).createShader(Offset.zero & size),
    );
    final letzter = werte.lastIndexWhere((v) => v != null);
    for (var i = 0; i < werte.length; i++) {
      final v = werte[i];
      if (v == null) continue;
      canvas.drawCircle(
        Offset(x(i), y(v)),
        i == letzter ? 5 : 3,
        Paint()
          ..color = i == letzter ? const Color(0xFFF5DFAE) : CoachStyle.gold,
      );
    }
    for (final (i, t) in [
      (0, 'vor ${werte.length - 1} Wo.'),
      (werte.length - 1, 'diese Woche'),
    ]) {
      tp.text = TextSpan(text: t, style: tSoft.copyWith(fontSize: 10));
      tp.layout();
      tp.paint(
        canvas,
        Offset(
          (x(i) - tp.width / 2).clamp(0, size.width - tp.width),
          size.height - 14,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_KurveMaler old) => old.werte != werte;
}
