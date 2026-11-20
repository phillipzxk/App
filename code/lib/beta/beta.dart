import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../bereiche/glas.dart';
import '../coach/remote_coach.dart';
import '../konto/konto_ui.dart';
import '../mindset/mindset_ui.dart';
import '../ui/coach_style.dart';
import '../ui/umbau.dart';

/// Beta for testers (vault Umsetzung/Beta.md): the Android app comes from
/// our own invite page, not the Play Store, so it checks itself for a new
/// version. The build number is set when the APK is built.
const betaBuild = int.fromEnvironment('BETA_BUILD');

/// Where the invite page, the APK and version.json live.
const betaSeite = String.fromEnvironment(
  'BETA_URL',
  defaultValue: 'https://groundset-vorschau.pzschernack4.workers.dev/beta/',
);

/// Only the downloaded Android app needs the check: the web app updates
/// itself, and iPhone has no APK.
bool get betaUpdatesAn =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android && betaBuild > 0;

/// The newer build on the server, or null when this one is current.
Future<({int build, String apk})?> neueVersion({http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final r = await c
        .get(Uri.parse('${betaSeite}version.json'))
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final b = (j['build'] as num?)?.toInt() ?? 0;
    if (b <= betaBuild) return null;
    return (build: b, apk: '${j['apk'] ?? '${betaSeite}groundset.apk'}');
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// Lays a small gold card over the app when a new version is waiting.
class BetaUpdateHinweis extends StatefulWidget {
  const BetaUpdateHinweis({super.key, required this.child, this.pruefen});

  final Widget child;

  /// For tests; the real check runs only in the Android beta app.
  final Future<({int build, String apk})?> Function()? pruefen;

  @override
  State<BetaUpdateHinweis> createState() => _BetaUpdateHinweisState();
}

class _BetaUpdateHinweisState extends State<BetaUpdateHinweis> {
  ({int build, String apk})? _neu;
  bool _weg = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pruefen ?? (betaUpdatesAn ? neueVersion : null);
    p?.call().then((v) {
      if (mounted && v != null) setState(() => _neu = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final neu = _neu;
    return Stack(
      children: [
        widget.child,
        if (neu != null && !_weg)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.paddingOf(context).bottom + 96,
            child: Material(
              type: MaterialType.transparency,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Transform.translate(
                  offset: Offset(0, 40 * (1 - t)),
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
                child: GlasBox(
                  key: const ValueKey('beta-update'),
                  art: GlasArt.gold,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.system_update_alt_rounded,
                        color: CoachStyle.goldLight,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Neue Version da',
                              style: Glas.tText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Laden, installieren, fertig. Deine Daten '
                              'bleiben.',
                              style: Glas.tSoft.copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(neu.apk),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: const Text(
                          'Jetzt laden',
                          style: TextStyle(
                            color: CoachStyle.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Später',
                        onPressed: () => setState(() => _weg = true),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Glas.soft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Sends a tester's message to the coach server, where it is kept for
/// Phillip.
Future<bool> feedbackSenden(
  String text, {
  String name = '',
  http.Client? client,
}) async {
  if (coachUrl.isEmpty) return false;
  final c = client ?? http.Client();
  try {
    final r = await c
        .post(
          Uri.parse('$coachUrl/feedback'),
          headers: {
            'content-type': 'application/json',
            'x-app-token': coachToken,
          },
          body: jsonEncode({
            'text': text,
            'name': name,
            'geraet': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'build': betaBuild,
          }),
        )
        .timeout(const Duration(seconds: 12));
    return r.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    if (client == null) c.close();
  }
}

/// "Feedback geben": one field, one button, a thank-you.
class FeedbackSeite extends StatefulWidget {
  const FeedbackSeite({super.key, this.name = '', this.senden});

  final String name;
  final Future<bool> Function(String text)? senden;

  @override
  State<FeedbackSeite> createState() => _FeedbackSeiteState();
}

class _FeedbackSeiteState extends State<FeedbackSeite> {
  final _text = TextEditingController();
  bool _laeuft = false;
  bool _danke = false;
  String? _fehler;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _schicken() async {
    final t = _text.text.trim();
    if (t.isEmpty || _laeuft) return;
    setState(() {
      _laeuft = true;
      _fehler = null;
    });
    final ok =
        await (widget.senden?.call(t) ?? feedbackSenden(t, name: widget.name));
    if (!mounted) return;
    setState(() {
      _laeuft = false;
      _danke = ok;
      _fehler = ok ? null : 'Das hat nicht geklappt. Bist du online?';
    });
  }

  @override
  Widget build(BuildContext context) => KontoHintergrund(
    lichtY: 0,
    child: ListView(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ZurueckPille(label: 'Einstellungen'),
          ),
        ),
        const GoldSchrift(
          'Feedback geben',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            fontSize: 25,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Was nervt, was fehlt, was gefällt dir? Sag es ehrlich, jede '
          'Nachricht wird gelesen.',
          style: Glas.tSoft.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 16),
        if (_danke)
          GlasBox(
            key: const ValueKey('feedback-danke'),
            art: GlasArt.gold,
            child: Text(
              'Danke! Deine Nachricht ist angekommen.',
              style: Glas.tText.copyWith(fontWeight: FontWeight.w600),
            ),
          )
        else ...[
          GlasFeld(
            key: const ValueKey('feedback-feld'),
            controller: _text,
            hint: 'z. B. Der Check-in ist mir abends zu lang',
            zeilen: 5,
          ),
          const SizedBox(height: 12),
          GlasKnopf(
            key: const ValueKey('feedback-senden'),
            label: _laeuft ? 'Wird geschickt …' : 'Abschicken',
            onTap: _laeuft ? null : _schicken,
          ),
          if (_fehler != null) ...[
            const SizedBox(height: 10),
            Text(_fehler!, style: Glas.tSoft),
          ],
        ],
      ],
    ),
  );
}
