import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bereiche/glas.dart';
import '../ui/coach_style.dart';
import '../ui/coach_widgets.dart';
import 'konto_daten.dart';
import 'konto_dienst.dart';
import 'konto_ui.dart';
import 'konto_web.dart';
import 'sicherung.dart';

/// Account after the questionnaire (vault Umsetzung/Konto und Sicherung,
/// Entwurf 2, Phillip "Ja passt" 2026-11-01): start, e-mail code,
/// "Gesichert", then on to the first check-in.
///
/// With [zurueck] it is "Ich habe schon ein Konto": the backup comes back
/// onto this phone instead of being made.
class KontoFlow extends StatefulWidget {
  const KontoFlow({
    super.key,
    required this.dienst,
    required this.store,
    required this.sicherung,
    required this.onFertig,
    this.name = '',
    this.ziel = '',
    this.zurueck = false,
    this.onAbbrechen,
  });

  final KontoDienst dienst;
  final KontoStore store;
  final Sicherung sicherung;
  final String name;
  final String ziel;
  final bool zurueck;

  /// [wiederhergestellt] is true when a backup came back onto this phone.
  final void Function(bool wiederhergestellt) onFertig;

  /// Back from the start screen (only for "Ich habe schon ein Konto").
  final VoidCallback? onAbbrechen;

  @override
  State<KontoFlow> createState() => _KontoFlowState();
}

enum _Schritt { start, email, gesichert }

class _KontoFlowState extends State<KontoFlow> {
  _Schritt _schritt = _Schritt.start;
  bool _laedt = false;
  bool _wieder = false;
  String? _fehler;

  Future<void> _angemeldet(Konto k) async {
    await widget.store.saveKonto(k);
    if (widget.zurueck) {
      final da = await widget.sicherung.wiederherstellen();
      if (!mounted) return;
      if (!da) {
        setState(() {
          _laedt = false;
          _fehler =
              'Unter diesem Konto gibt es noch keine Sicherung. Wir legen '
              'jetzt neu los.';
        });
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        widget.onFertig(false);
        return;
      }
      _wieder = true;
    } else {
      try {
        await widget.sicherung.sichern();
      } on KontoFehler {
        // Not fatal: the next backup runs later on its own.
      }
    }
    if (mounted) {
      setState(() {
        _laedt = false;
        _schritt = _Schritt.gesichert;
      });
    }
  }

  Future<void> _anbieter(Anmeldeart art) async {
    final d = widget.dienst;
    if (!d.anbieterAn(art)) {
      setState(
        () => _fehler =
            'Die Anmeldung mit ${art.label} kommt mit der Handy-Version. '
            'Nimm solange den E-Mail-Code.',
      );
      return;
    }
    setState(() {
      _laedt = true;
      _fehler = null;
    });
    if (d is VorschauKontoDienst) {
      await _angemeldet(d.anbieterKonto(art));
    } else if (d is SupabaseKontoDienst) {
      final hier = aktuelleAdresse();
      if (hier != null) {
        zuAdresse(d.anbieterAdresse(art, hier.replace(fragment: '')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 450),
    child: switch (_schritt) {
      _Schritt.start => _StartSeite(
        key: const ValueKey('konto-start'),
        zurueck: widget.zurueck,
        laedt: _laedt,
        fehler: _fehler,
        vorschau: !widget.dienst.echt,
        onApple: () => _anbieter(Anmeldeart.apple),
        onGoogle: () => _anbieter(Anmeldeart.google),
        onEmail: () => setState(() {
          _fehler = null;
          _schritt = _Schritt.email;
        }),
        onAbbrechen: widget.onAbbrechen,
      ),
      _Schritt.email => _EmailSeite(
        key: const ValueKey('konto-email'),
        dienst: widget.dienst,
        hinweis: _fehler,
        onZurueck: () => setState(() => _schritt = _Schritt.start),
        onAngemeldet: _angemeldet,
      ),
      _Schritt.gesichert => _GesichertSeite(
        key: const ValueKey('konto-gesichert'),
        name: widget.name,
        ziel: widget.ziel,
        wieder: _wieder,
        onWeiter: () => widget.onFertig(_wieder),
      ),
    },
  );
}

// ------------------------------------------------------------------ Start

class _StartSeite extends StatefulWidget {
  const _StartSeite({
    super.key,
    required this.zurueck,
    required this.laedt,
    required this.fehler,
    required this.vorschau,
    required this.onApple,
    required this.onGoogle,
    required this.onEmail,
    this.onAbbrechen,
  });

  final bool zurueck;
  final bool laedt;
  final String? fehler;
  final bool vorschau;
  final VoidCallback onApple;
  final VoidCallback onGoogle;
  final VoidCallback onEmail;
  final VoidCallback? onAbbrechen;

  @override
  State<_StartSeite> createState() => _StartSeiteState();
}

class _StartSeiteState extends State<_StartSeite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KontoHintergrund(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: widget.onAbbrechen == null
              ? null
              : Align(
                  alignment: Alignment.centerLeft,
                  child: _Zurueck(onTap: widget.onAbbrechen!),
                ),
        ),
        const Spacer(),
        const Center(child: WachsendesLogo(size: 150)),
        const SizedBox(height: 4),
        Center(
          child: Auftritt(anim: _a, start: .2, child: const KontoWortmarke()),
        ),
        const SizedBox(height: 26),
        Auftritt(
          anim: _a,
          start: .45,
          child: Column(
            children: [
              GoldSchrift(
                widget.zurueck
                    ? 'Willkommen zurück.'
                    : 'Bau dein Fundament\nfürs Leben.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 31,
                  height: 1.12,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  widget.zurueck
                      ? 'Melde dich an wie beim letzten Mal. Dann holst du '
                            'alles auf dieses Handy zurück.'
                      : 'Ein Konto, und alles, was du hier aufbaust, bleibt '
                            'bei dir. Jeder Tag, jedes Training, jedes Foto.',
                  textAlign: TextAlign.center,
                  style: Glas.tSoft.copyWith(fontSize: 14.5, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Auftritt(
          anim: _a,
          start: .62,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.fehler != null) ...[
                Text(
                  widget.fehler!,
                  key: const ValueKey('konto-fehler'),
                  textAlign: TextAlign.center,
                  style: Glas.tSoft.copyWith(color: const Color(0xFFF3DCA6)),
                ),
                const SizedBox(height: 10),
              ],
              KontoKnopf(
                key: const ValueKey('konto-apple'),
                label: 'Mit Apple fortfahren',
                icon: const Icon(
                  Icons.apple,
                  size: 20,
                  color: CoachStyle.goldInk,
                ),
                laedt: widget.laedt,
                onTap: widget.onApple,
              ),
              const SizedBox(height: 10),
              KontoKnopf(
                key: const ValueKey('konto-google'),
                label: 'Mit Google fortfahren',
                art: KnopfArt.glas,
                icon: const _GoogleG(),
                onTap: widget.laedt ? null : widget.onGoogle,
              ),
              const SizedBox(height: 10),
              KontoKnopf(
                key: const ValueKey('konto-email'),
                label: 'Mit E-Mail-Code',
                art: KnopfArt.linie,
                icon: const Icon(
                  Icons.mail_outline,
                  size: 19,
                  color: Color(0xFFF3DCA6),
                ),
                onTap: widget.laedt ? null : widget.onEmail,
              ),
              const SizedBox(height: 14),
              Text(
                widget.vorschau
                    ? 'Vorschau: noch ohne Server, nichts verlässt dein Gerät.'
                    : 'Kein Passwort. Deine Daten gehören dir.',
                textAlign: TextAlign.center,
                style: Glas.tSoft.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      fontFamily: 'Sora',
      fontWeight: FontWeight.w700,
      fontSize: 16,
      color: Color(0xFFF3DCA6),
    ),
  );
}

class _Zurueck extends StatelessWidget {
  const _Zurueck({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    key: const ValueKey('konto-zurueck'),
    onPressed: onTap,
    icon: const Icon(Icons.chevron_left, color: Glas.label, size: 20),
    label: Text('Zurück', style: Glas.tLabel),
  );
}

// ------------------------------------------------------------------ E-Mail

class _EmailSeite extends StatefulWidget {
  const _EmailSeite({
    super.key,
    required this.dienst,
    required this.onZurueck,
    required this.onAngemeldet,
    this.hinweis,
  });

  final KontoDienst dienst;
  final VoidCallback onZurueck;
  final Future<void> Function(Konto) onAngemeldet;
  final String? hinweis;

  @override
  State<_EmailSeite> createState() => _EmailSeiteState();
}

class _EmailSeiteState extends State<_EmailSeite>
    with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();
  late final AnimationController _brief = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  final _mail = TextEditingController();
  final _code = TextEditingController();
  final _codeFokus = FocusNode();
  bool _gesendet = false;
  bool _laedt = false;
  bool _stimmt = false;
  String? _fehler;

  @override
  void dispose() {
    _a.dispose();
    _brief.dispose();
    _mail.dispose();
    _code.dispose();
    _codeFokus.dispose();
    super.dispose();
  }

  bool get _mailOk =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_mail.text.trim());

  Future<void> _senden() async {
    setState(() {
      _laedt = true;
      _fehler = null;
    });
    try {
      await widget.dienst.codeSenden(_mail.text.trim());
      if (!mounted) return;
      setState(() {
        _gesendet = true;
        _laedt = false;
      });
      _brief.forward(from: 0);
      // After the frame, so the code field exists before it gets focus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFokus.requestFocus();
      });
    } on KontoFehler catch (e) {
      setState(() {
        _fehler = e.text;
        _laedt = false;
      });
    } catch (_) {
      setState(() {
        _fehler = 'Keine Verbindung. Versuch es gleich nochmal.';
        _laedt = false;
      });
    }
  }

  Future<void> _pruefen() async {
    if (_code.text.length < 6 || _laedt) return;
    setState(() {
      _laedt = true;
      _fehler = null;
    });
    try {
      final k = await widget.dienst.codePruefen(_mail.text.trim(), _code.text);
      if (!mounted) return;
      setState(() => _stimmt = true);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await widget.onAngemeldet(k);
    } on KontoFehler catch (e) {
      setState(() {
        _fehler = e.text;
        _laedt = false;
        _code.clear();
      });
    } catch (_) {
      setState(() {
        _fehler = 'Keine Verbindung. Versuch es gleich nochmal.';
        _laedt = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => KontoHintergrund(
    lichtY: .12,
    child: ListView(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _Zurueck(onTap: widget.onZurueck),
        ),
        Auftritt(
          anim: _a,
          start: 0,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 92,
              child: AnimatedBuilder(
                animation: _brief,
                builder: (context, _) =>
                    CustomPaint(painter: _BriefMaler(_brief.value)),
              ),
            ),
          ),
        ),
        Auftritt(
          anim: _a,
          start: .1,
          child: Center(
            child: GoldSchrift(
              _gesendet ? 'Schau in dein Postfach' : 'Deine E-Mail',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 25,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Auftritt(
          anim: _a,
          start: .2,
          child: _GlasEingabe(
            key: const ValueKey('konto-mail'),
            controller: _mail,
            enabled: !_gesendet,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _mailOk ? _senden() : null,
          ),
        ),
        const SizedBox(height: 14),
        if (!_gesendet)
          Auftritt(
            anim: _a,
            start: .3,
            child: KontoKnopf(
              key: const ValueKey('konto-code-senden'),
              label: 'Code schicken',
              laedt: _laedt,
              onTap: _mailOk ? _senden : null,
            ),
          )
        else
          GlasBox(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Column(
              children: [
                Text(
                  'CODE AUS DER MAIL',
                  style: Glas.tLabel.copyWith(fontSize: 11, letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                _CodeFelder(
                  controller: _code,
                  fokus: _codeFokus,
                  stimmt: _stimmt,
                  onChanged: (_) {
                    setState(() {});
                    if (_code.text.length == 6) _pruefen();
                  },
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _stimmt
                      ? Row(
                          key: const ValueKey('stimmt'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 17,
                              color: Color(0xFFF3DCA6),
                            ),
                            const SizedBox(width: 6),
                            Text('Stimmt, du bist drin', style: Glas.tLabel),
                          ],
                        )
                      : TextButton(
                          key: const ValueKey('neu-schicken'),
                          onPressed: _laedt ? null : _senden,
                          child: Text(
                            'Nichts angekommen? Neu schicken',
                            style: Glas.tSoft.copyWith(color: Glas.label),
                          ),
                        ),
                ),
              ],
            ),
          ),
        if ((_fehler ?? widget.hinweis) case final f?) ...[
          const SizedBox(height: 12),
          Text(
            f,
            key: const ValueKey('konto-fehler'),
            textAlign: TextAlign.center,
            style: Glas.tSoft.copyWith(color: const Color(0xFFF3DCA6)),
          ),
        ],
        const SizedBox(height: 22),
        Auftritt(
          anim: _a,
          start: .45,
          child: KontoCoach(
            avatar: const CoachAvatar(size: 34),
            text: _gesendet
                ? 'Die 6 Zahlen sind unterwegs. Kommt nichts an, schau kurz '
                      'im Spam.'
                : 'Ich schicke dir 6 Zahlen. Kein Passwort, das du dir '
                      'merken musst.',
          ),
        ),
        if (!widget.dienst.echt) ...[
          const SizedBox(height: 10),
          Text(
            'Vorschau: Es kommt keine Mail, tipp einfach 6 beliebige Zahlen.',
            textAlign: TextAlign.center,
            style: Glas.tSoft.copyWith(fontSize: 12),
          ),
        ],
      ],
    ),
  );
}

class _GlasEingabe extends StatelessWidget {
  const _GlasEingabe({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final rand = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0x8CE0BF7E)),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.send,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: const Color(0xFFF3DCA6),
      style: Glas.tText.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'deine@mail.de',
        hintStyle: Glas.tSoft.copyWith(fontSize: 15),
        prefixIcon: const Icon(Icons.mail_outline, color: Glas.label, size: 19),
        filled: true,
        fillColor: const Color(0x14FFECDC),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 14,
        ),
        border: rand,
        enabledBorder: rand,
        disabledBorder: rand.copyWith(
          borderSide: const BorderSide(color: Glas.edge),
        ),
        focusedBorder: rand.copyWith(
          borderSide: const BorderSide(color: Color(0xFFE0BF7E), width: 1.4),
        ),
      ),
    );
  }
}

/// Six boxes that fill gold one by one while typing.
class _CodeFelder extends StatelessWidget {
  const _CodeFelder({
    required this.controller,
    required this.fokus,
    required this.stimmt,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode fokus;
  final bool stimmt;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = controller.text;
    return Stack(
      children: [
        // The real input over the boxes: text and cursor transparent, so
        // focus and typing work on web too (Opacity 0 loses the keyboard).
        Positioned.fill(
          child: TextField(
            key: const ValueKey('konto-code'),
            controller: controller,
            focusNode: fokus,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              counterText: '',
              isCollapsed: true,
            ),
          ),
        ),
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                _CodeKasten(
                  ziffer: i < t.length ? t[i] : '',
                  aktiv: i == t.length,
                  stimmt: stimmt,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CodeKasten extends StatelessWidget {
  const _CodeKasten({
    required this.ziffer,
    required this.aktiv,
    required this.stimmt,
  });

  final String ziffer;
  final bool aktiv;
  final bool stimmt;

  @override
  Widget build(BuildContext context) {
    final voll = ziffer.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      width: 42,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: stimmt
            ? const LinearGradient(
                colors: [Color(0x40F6E2B0), Color(0x1AE0BF7E)],
              )
            : Glas.fill,
        border: Border.all(
          color: voll || aktiv ? const Color(0xD9E0BF7E) : Glas.edge,
          width: aktiv ? 1.5 : 1,
        ),
        boxShadow: voll
            ? const [BoxShadow(color: Color(0x59E0BF7E), blurRadius: 16)]
            : null,
      ),
      child: AnimatedScale(
        scale: voll ? 1 : .4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: Text(
          ziffer,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 23,
            color: Color(0xFFF8E6B8),
          ),
        ),
      ),
    );
  }
}

/// An envelope; when the code is sent a small gold paper plane flies off.
class _BriefMaler extends CustomPainter {
  _BriefMaler(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8E6B8), Color(0xFFC08E45)],
      ).createShader(Offset.zero & s);
    final r = RRect.fromLTRBR(14, 32, 72, 74, const Radius.circular(9));
    c.drawRRect(r, Paint()..color = const Color(0x14FFECDC));
    c.drawRRect(
      r,
      Paint()
        ..shader = gold.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawPath(
      Path()
        ..moveTo(17, 36)
        ..lineTo(43, 55)
        ..lineTo(69, 36),
      Paint()
        ..shader = gold.shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (t <= 0 || t >= 1) return;
    final p = Curves.easeInOut.transform(t);
    final dx = 40 + 50 * p;
    final dy = 44 - 50 * p;
    final a = (t < .2 ? t / .2 : (1 - t) / .8).clamp(0.0, 1.0);
    c
      ..save()
      ..translate(dx, dy)
      ..rotate(-.2 + .4 * p)
      ..drawPath(
        Path()
          ..moveTo(-8, 4)
          ..lineTo(14, -6)
          ..lineTo(6, 12)
          ..lineTo(2, 4)
          ..close(),
        Paint()..color = const Color(0xFFF3DCA6).withValues(alpha: a),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_BriefMaler o) => o.t != t;
}

// --------------------------------------------------------------- Gesichert

class _GesichertSeite extends StatefulWidget {
  const _GesichertSeite({
    super.key,
    required this.name,
    required this.ziel,
    required this.wieder,
    required this.onWeiter,
  });

  final String name;
  final String ziel;
  final bool wieder;
  final VoidCallback onWeiter;

  @override
  State<_GesichertSeite> createState() => _GesichertSeiteState();
}

class _GesichertSeiteState extends State<_GesichertSeite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward();

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  String get _titel {
    final n = widget.name.trim();
    if (widget.wieder) {
      return n.isEmpty ? 'Alles ist wieder da.' : '$n, alles ist\nwieder da.';
    }
    return n.isEmpty ? 'Dein Fundament\nsteht.' : '$n, dein\nFundament steht.';
  }

  @override
  Widget build(BuildContext context) {
    final ziel = widget.ziel.trim();
    return KontoHintergrund(
      lichtY: .22,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _a,
                builder: (context, _) =>
                    CustomPaint(painter: _FunkenMaler(_a.value)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              const Center(child: WachsendesLogo(size: 170, leuchten: true)),
              Auftritt(
                anim: _a,
                start: .5,
                child: Column(
                  children: [
                    Text(
                      widget.wieder ? 'ZURÜCKGEHOLT' : 'GESICHERT',
                      style: Glas.tLabel.copyWith(
                        fontSize: 12,
                        letterSpacing: 2.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GoldSchrift(
                      _titel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1.12,
                        letterSpacing: -.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Auftritt(
                anim: _a,
                start: .62,
                child: GlasBox(
                  art: GlasArt.gold,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ziel.isNotEmpty) ...[
                        Text(
                          widget.wieder
                              ? 'Dein Ziel:'
                              : 'Dein Ziel, sicher bei dir:',
                          style: Glas.tSoft,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '„$ziel“',
                          key: const ValueKey('gesichert-ziel'),
                          style: const TextStyle(
                            fontFamily: 'Sora',
                            fontWeight: FontWeight.w700,
                            fontSize: 19,
                            height: 1.3,
                            color: Glas.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CoachAvatar(size: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.wieder
                                  ? 'Dein Plan, deine Einträge und deine Fotos '
                                        'sind zurück. Wir machen genau da '
                                        'weiter, wo du aufgehört hast.'
                                  : 'Alles, was du mir erzählt hast, ist jetzt '
                                        'sicher. Ab heute wächst dein Fundament '
                                        'jeden Tag ein Stück.',
                              style: Glas.tText.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Auftritt(
                anim: _a,
                start: .7,
                child: KontoKnopf(
                  key: const ValueKey('konto-weiter'),
                  label: widget.wieder ? 'Weiter' : 'Zum ersten Check-in',
                  onTap: widget.onWeiter,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A gold ring going out from the logo and sparks flying off, once the
/// roots light up.
class _FunkenMaler extends CustomPainter {
  _FunkenMaler(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final p = ((t - .55) / .35).clamp(0.0, 1.0);
    if (p <= 0 || p >= 1) return;
    final mitte = Offset(s.width / 2, 36 + 85.0 + 10);
    c.drawCircle(
      mitte,
      10 + 220 * Curves.easeOut.transform(p),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFF0C878).withValues(alpha: .8 * (1 - p)),
    );
    for (var i = 0; i < 9; i++) {
      final w = i / 9 * 2 * math.pi + .3;
      final d = 30 + 110 * Curves.easeOut.transform(p);
      c.drawCircle(
        mitte + Offset(math.cos(w) * d, math.sin(w) * d),
        2.6 * (1 - p) + .6,
        Paint()..color = const Color(0xFFF8E6B8).withValues(alpha: 1 - p),
      );
    }
  }

  @override
  bool shouldRepaint(_FunkenMaler o) => o.t != t;
}
