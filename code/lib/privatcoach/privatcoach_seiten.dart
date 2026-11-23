import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../konto/konto_ui.dart' show bewegungAn;
import '../ui/umbau.dart';
import 'privatcoach_daten.dart';
import 'chat_push.dart';
import 'privatcoach_dienst.dart';

/// The pages of the Privatcoach (vault Umsetzung/Phillip dazuholen.md,
/// Ablauf Entwurf 2, Phillip 2026-11-21 "also sehr gut"): like messages on
/// Insta, only nicer. Gold only, glass on espresso brown.

const _tintenText = TextStyle(
  fontFamily: 'Figtree',
  fontSize: 14.5,
  height: 1.38,
  color: Umbau.tinte,
);
const _text = TextStyle(
  fontFamily: 'Figtree',
  fontSize: 14.5,
  height: 1.38,
  color: Umbau.text,
);

/// Phillip's round picture: the gold "P" (his photo can replace it later)
/// with the gold check seal of a real person.
class PhillipAvatar extends StatelessWidget {
  const PhillipAvatar({super.key, this.groesse = 40, this.siegel = true});
  final double groesse;
  final bool siegel;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: groesse,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: Umbau.grad,
            boxShadow: [BoxShadow(color: Color(0x40E2C48A), blurRadius: 14)],
          ),
          alignment: Alignment.center,
          child: Text(
            'P',
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: groesse * .44,
              color: Umbau.tinte,
            ),
          ),
        ),
        if (siegel)
          Positioned(
            right: -2,
            bottom: -2,
            child: EchtSiegel(groesse: math.max(14, groesse * .38)),
          ),
      ],
    ),
  );
}

/// The small gold check: a real, verified person.
class EchtSiegel extends StatelessWidget {
  const EchtSiegel({super.key, this.groesse = 16});
  final double groesse;

  @override
  Widget build(BuildContext context) => Container(
    width: groesse,
    height: groesse,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: Umbau.grad,
      border: Border.all(color: const Color(0xFF1B1611), width: 2),
    ),
    child: Icon(Icons.check_rounded, size: groesse * .62, color: Umbau.tinte),
  );
}

/// A user's round initial on Phillip's side.
class NutzerAvatar extends StatelessWidget {
  const NutzerAvatar({super.key, required this.name, this.groesse = 44});
  final String name;
  final double groesse;

  @override
  Widget build(BuildContext context) => Container(
    width: groesse,
    height: groesse,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Klar.glasAn,
      border: Border.all(color: const Color(0x55F0D49A)),
    ),
    alignment: Alignment.center,
    child: Text(
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
      style: TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w600,
        fontSize: groesse * .4,
        color: Umbau.gold,
      ),
    ),
  );
}

/// The gold count of unread messages.
class UngelesenZahl extends StatelessWidget {
  const UngelesenZahl(this.zahl, {super.key});
  final int zahl;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 18),
    height: 18,
    padding: const EdgeInsets.symmetric(horizontal: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      gradient: Umbau.grad,
      border: Border.all(color: const Color(0xFF1B1611), width: 1.5),
    ),
    alignment: Alignment.center,
    child: Text(
      zahl > 9 ? '9+' : '$zahl',
      style: const TextStyle(
        fontFamily: 'Sora',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        color: Umbau.tinte,
      ),
    ),
  );
}

/// Before Phillip accepted: the small "P" in the corner above the plus,
/// with "1:1" (draft 3, clean and small).
class PrivatcoachEcke extends StatelessWidget {
  const PrivatcoachEcke({super.key, required this.onTap, this.ungelesen = 0});
  final VoidCallback onTap;
  final int ungelesen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Phillip schreiben, echtes 1:1 Coaching',
    excludeSemantics: true,
    child: GestureDetector(
      key: const ValueKey('privatcoach-ecke'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            const PhillipAvatar(groesse: 46),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2119),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0x66F0D49A)),
                ),
                child: const Text(
                  '1:1',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: .5,
                    color: Umbau.gold,
                  ),
                ),
              ),
            ),
            if (ungelesen > 0)
              Positioned(right: -4, top: -4, child: UngelesenZahl(ungelesen)),
          ],
        ),
      ),
    ),
  );
}

/// After Phillip accepted (or on Phillip's own account): the "P" sits in
/// the bar at the bottom, with the number of unread messages.
class LeistenP extends StatelessWidget {
  const LeistenP({
    super.key,
    required this.onTap,
    this.ungelesen = 0,
    this.alsCoach = false,
  });
  final VoidCallback onTap;
  final int ungelesen;
  final bool alsCoach;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: alsCoach ? 'Deine Nachrichten' : 'Chat mit Phillip',
    excludeSemantics: true,
    child: GestureDetector(
      key: const ValueKey('leiste-p'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox.square(
        dimension: 50,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (alsCoach)
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x17FFF5E6),
                  border: Border.all(color: const Color(0x55F0D49A)),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  size: 21,
                  color: Umbau.gold,
                ),
              )
            else
              const PhillipAvatar(groesse: 46),
            if (ungelesen > 0)
              Positioned(right: -3, top: -3, child: UngelesenZahl(ungelesen)),
          ],
        ),
      ),
    ),
  );
}

/// The page frame: lighter brown with slowly turning gold circles.
class _Rahmen extends StatelessWidget {
  const _Rahmen({required this.kopf, required this.child, this.unten});
  final Widget kopf;
  final Widget child;
  final Widget? unten;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF231B14),
    resizeToAvoidBottomInset: true,
    body: KlarHintergrund(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: kopf,
                ),
                Container(height: 1, color: Umbau.linie),
                Expanded(child: child),
                ?unten,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// What the user shares, read fresh before each send.
typedef WerteQuelle = Future<GeteilteWerte> Function();

/// The chat. The user writes to Phillip; with [alsCoach] Phillip writes
/// to [chatId]. New messages come in every few seconds while it is open.
class ChatSeite extends StatefulWidget {
  const ChatSeite({
    super.key,
    required this.dienst,
    required this.chatId,
    required this.name,
    this.alsCoach = false,
    this.werte,
    this.clock = DateTime.now,
    this.abholen = const Duration(seconds: 5),
    this.push = const ChatPush(),
  });

  final PrivatcoachDienst dienst;
  final ChatPush push;
  final String chatId;

  /// The user's own name (sent with the first message), or on Phillip's
  /// side the name of the person he writes with.
  final String name;
  final bool alsCoach;
  final WerteQuelle? werte;
  final DateTime Function() clock;
  final Duration abholen;

  @override
  State<ChatSeite> createState() => _ChatSeiteState();
}

class _ChatSeiteState extends State<ChatSeite> {
  final _feld = TextEditingController();
  final _scroll = ScrollController();
  List<CoachNachricht> _liste = const [];
  CoachChat? _chat;
  bool _frei = true;
  bool _geladen = false;
  bool _sendet = false;
  String? _fehler;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _laden(erstesMal: true);
    _timer = Timer.periodic(widget.abholen, (_) => _laden());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feld.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _laden({bool erstesMal = false}) async {
    try {
      final d = widget.dienst;
      final chat = widget.alsCoach
          ? (await d.alleChats())
                .where((c) => c.userId == widget.chatId)
                .firstOrNull
          : await d.meinChat();
      final liste = chat == null
          ? const <CoachNachricht>[]
          : await d.nachrichten(widget.chatId);
      final frei = chat != null || widget.alsCoach || await d.frei();
      if (chat != null &&
          liste.any(
            (n) => n.vonCoach != widget.alsCoach && n.gelesen == null,
          )) {
        await d.gelesen(widget.chatId);
      }
      if (!mounted) return;
      final neu = liste.length != _liste.length;
      setState(() {
        _chat = chat;
        _liste = liste;
        _frei = frei;
        _geladen = true;
      });
      if (neu || erstesMal) _nachUnten();
    } catch (_) {
      if (mounted) setState(() => _geladen = true);
    }
  }

  void _nachUnten() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: Duration(milliseconds: bewegungAn ? 350 : 1),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _senden() async {
    final text = _feld.text.trim();
    if (text.isEmpty || _sendet) return;
    // The first message: may Phillip see the values?
    bool? teilen;
    if (!widget.alsCoach && _chat == null && widget.werte != null) {
      teilen = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const WerteFrage(),
      );
      if (teilen == null) return;
    }
    setState(() {
      _sendet = true;
      _fehler = null;
    });
    try {
      await widget.dienst.senden(
        widget.chatId,
        text,
        name: widget.alsCoach ? null : widget.name,
      );
      final q = widget.werte;
      if (!widget.alsCoach && q != null) {
        if (teilen == true || (teilen == null && _chat?.werteErlaubt == true)) {
          await widget.dienst.werteTeilen(await q());
        }
      }
      _feld.clear();
      await _laden();
    } on ChatFehler catch (e) {
      if (mounted) setState(() => _fehler = e.text);
    } catch (_) {
      if (mounted) {
        setState(
          () => _fehler =
              'Das hat nicht geklappt. Prüf dein Internet und versuch es '
              'nochmal.',
        );
      }
    } finally {
      if (mounted) setState(() => _sendet = false);
    }
  }

  Future<void> _annehmen() async {
    await widget.dienst.annehmen(widget.chatId);
    await _laden();
  }

  @override
  Widget build(BuildContext context) {
    final chat = _chat;
    return _Rahmen(
      kopf: widget.alsCoach ? _kopfCoach(chat) : _kopfNutzer(),
      unten: _unten(chat),
      child: !_geladen
          ? const Center(child: CircularProgressIndicator(color: Umbau.gold))
          : ListView(
              key: const ValueKey('chat-liste'),
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              children: [
                if (!widget.alsCoach) ...[
                  const _Blase(
                    text:
                        'Schreib mir, wo es gerade hängt. Ich antworte selbst.',
                    vonPhillip: true,
                  ),
                  if (chat?.fokus case final f?) _FokusKarte(fokus: f),
                ],
                if (widget.alsCoach && chat != null && chat.werteErlaubt)
                  WerteKarte(
                    name: chat.name,
                    werte: chat.werte ?? const GeteilteWerte(),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => GeteilteWerteSeite(
                          dienst: widget.dienst,
                          chat: chat,
                          onGeaendert: _laden,
                        ),
                      ),
                    ),
                  ),
                for (final (i, n) in _liste.indexed) ...[
                  _Blase(
                    key: ValueKey('nachricht-${n.id}'),
                    text: n.text,
                    vonPhillip: n.vonCoach,
                    eigene: n.vonCoach == widget.alsCoach,
                    zeit: chatZeit(n.erstellt, widget.clock()),
                    sekunden: n.audio == null ? null : (n.sekunden ?? 0),
                  ),
                  if (i == _liste.length - 1 &&
                      n.vonCoach == widget.alsCoach &&
                      n.gelesen != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 4, bottom: 6),
                      child: Text(
                        'Gesehen',
                        key: ValueKey('chat-gesehen'),
                        textAlign: TextAlign.right,
                        style: Umbau.klein,
                      ),
                    ),
                ],
                if (!widget.alsCoach && chat?.status == ChatStatus.anfrage)
                  const _Hinweis(
                    key: ValueKey('chat-anfrage'),
                    text:
                        'Anfrage gesendet. Phillip schaut sie sich selbst an '
                        'und meldet sich hier.',
                  ),
                if (chat != null)
                  PushHinweis(
                    dienst: widget.dienst,
                    push: widget.push,
                    alsCoach: widget.alsCoach,
                  ),
              ],
            ),
    );
  }

  Widget _kopfNutzer() => Row(
    children: [
      const ZurueckPille(),
      const SizedBox(width: 12),
      const PhillipAvatar(groesse: 42),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Phillip',
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Umbau.text,
                  ),
                ),
                SizedBox(width: 5),
                EchtSiegel(groesse: 15),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Echter Mensch · keine KI',
              key: const ValueKey('chat-echt'),
              style: Umbau.klein.copyWith(color: Umbau.gold),
            ),
            const Text('Antwortet meist am selben Tag', style: Umbau.klein),
          ],
        ),
      ),
    ],
  );

  Widget _kopfCoach(CoachChat? chat) {
    final seit = chat?.werte?.seitTagen;
    return Row(
      children: [
        const ZurueckPille(),
        const SizedBox(width: 12),
        NutzerAvatar(name: widget.name, groesse: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name.isEmpty ? 'Ohne Namen' : widget.name,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Umbau.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                seit == null
                    ? 'nutzt Groundset'
                    : 'nutzt Groundset seit $seit ${seit == 1 ? 'Tag' : 'Tagen'}',
                style: Umbau.klein,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unten(CoachChat? chat) {
    final Widget inhalt;
    if (!_geladen) {
      inhalt = const SizedBox.shrink();
    } else if (widget.alsCoach && chat?.status == ChatStatus.anfrage) {
      inhalt = Row(
        children: [
          Expanded(
            child: Text(
              'Anfrage von ${widget.name.isEmpty ? 'jemandem' : widget.name}',
              style: Umbau.titel,
            ),
          ),
          _GoldKnopf(
            key: const ValueKey('chat-annehmen'),
            text: 'Annehmen',
            onTap: _annehmen,
          ),
        ],
      );
    } else if (!widget.alsCoach && chat == null && !_frei) {
      inhalt = const _Hinweis(
        key: ValueKey('chat-voll'),
        text:
            'Gerade voll. Alle Plätze der Testphase sind belegt. Sobald einer '
            'frei wird, kannst du Phillip hier schreiben.',
      );
    } else if (chat?.status == ChatStatus.beendet) {
      inhalt = const _Hinweis(text: 'Euer Coaching ist beendet.');
    } else {
      inhalt = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_fehler != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 6),
              child: Text(
                _fehler!,
                key: const ValueKey('chat-fehler'),
                style: Umbau.klein.copyWith(color: Umbau.gold),
              ),
            ),
          _Eingabe(feld: _feld, sendet: _sendet, onSenden: _senden),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        10 + MediaQuery.paddingOf(context).bottom * 0,
      ),
      child: inhalt,
    );
  }
}

/// The field at the bottom: "Nachricht …" and the gold send circle.
class _Eingabe extends StatelessWidget {
  const _Eingabe({
    required this.feld,
    required this.sendet,
    required this.onSenden,
  });
  final TextEditingController feld;
  final bool sendet;
  final VoidCallback onSenden;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 4, 5, 4),
    decoration: BoxDecoration(
      color: Klar.glas,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0x24FFF5E6)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('chat-feld'),
            controller: feld,
            minLines: 1,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            style: _text,
            cursorColor: Umbau.gold,
            onSubmitted: (_) => onSenden(),
            decoration: const InputDecoration(
              hintText: 'Nachricht …',
              hintStyle: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 14.5,
                color: Umbau.weich,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Semantics(
          button: true,
          label: 'Senden',
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('chat-senden'),
            onTap: sendet ? null : onSenden,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 1),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: Umbau.grad,
              ),
              child: sendet
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Umbau.tinte,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      size: 21,
                      color: Umbau.tinte,
                    ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// One message. Phillip's carry "von Phillips Handy".
class _Blase extends StatelessWidget {
  const _Blase({
    super.key,
    required this.text,
    required this.vonPhillip,
    this.eigene = false,
    this.zeit,
    this.sekunden,
  });

  final String text;
  final bool vonPhillip;

  /// Written by whoever looks at the chat: right side, gold.
  final bool eigene;
  final String? zeit;

  /// A voice message of this length.
  final int? sekunden;

  @override
  Widget build(BuildContext context) {
    final rechts = eigene;
    final inhalt = sekunden != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: rechts ? Umbau.tinte : Umbau.gold,
              ),
              const SizedBox(width: 6),
              Text(
                'Sprachnachricht · ${dauerText(sekunden!)}',
                style: rechts ? _tintenText : _text,
              ),
            ],
          )
        : Text(text, style: rechts ? _tintenText : _text);
    final unter = [if (vonPhillip) 'von Phillips Handy', ?zeit].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: rechts
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * .76,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                gradient: rechts ? Umbau.grad : null,
                color: rechts ? null : Klar.glas,
                border: rechts
                    ? null
                    : Border.all(color: const Color(0x1FFFF5E6)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(rechts ? 20 : 6),
                  bottomRight: Radius.circular(rechts ? 6 : 20),
                ),
              ),
              child: inhalt,
            ),
          ),
          if (unter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(unter, style: Umbau.klein.copyWith(fontSize: 10.5)),
            ),
        ],
      ),
    );
  }
}

class _Hinweis extends StatelessWidget {
  const _Hinweis({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Umbau.klein.copyWith(fontSize: 12.5),
    ),
  );
}

/// "Sag mir Bescheid": switches on notifications for the chat. Hidden
/// when they are on or not possible on this device.
class PushHinweis extends StatefulWidget {
  const PushHinweis({
    super.key,
    required this.dienst,
    required this.push,
    this.alsCoach = false,
  });
  final PrivatcoachDienst dienst;
  final ChatPush push;
  final bool alsCoach;

  @override
  State<PushHinweis> createState() => _PushHinweisState();
}

class _PushHinweisState extends State<PushHinweis> {
  late PushStand _stand = widget.push.stand();
  bool _laeuft = false;
  bool _fertig = false;

  Future<void> _an() async {
    if (_laeuft) return;
    setState(() => _laeuft = true);
    var ok = false;
    try {
      ok = await widget.push.an(widget.dienst);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _laeuft = false;
      _fertig = ok;
      _stand = ok ? PushStand.erlaubt : widget.push.stand();
    });
  }

  @override
  void initState() {
    super.initState();
    widget.push.pruefen().then((s) {
      if (!mounted) return;
      if (s != _stand) setState(() => _stand = s);
      // Already allowed: renew the subscription quietly (new device, key).
      if (s == PushStand.erlaubt) widget.push.an(widget.dienst);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_fertig) {
      return const _Hinweis(
        key: ValueKey('push-fertig'),
        text: 'Benachrichtigungen sind an.',
      );
    }
    final text = switch (_stand) {
      PushStand.frage =>
        widget.alsCoach
            ? 'Damit du keine Nachricht verpasst.'
            : 'Damit du siehst, wenn Phillip antwortet.',
      PushStand.homescreen =>
        'Für Benachrichtigungen: in Safari auf Teilen tippen, dann „Zum '
            'Home-Bildschirm“, und Groundset von dort öffnen.',
      PushStand.blockiert =>
        'Benachrichtigungen sind blockiert. Du kannst sie in den '
            'Einstellungen deines Handys für Groundset erlauben.',
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('push-hinweis'),
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Klar.glas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Umbau.linie),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Umbau.gold,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Umbau.klein.copyWith(fontSize: 13, color: Umbau.text),
            ),
          ),
          if (_stand == PushStand.frage) ...[
            const SizedBox(width: 10),
            _GoldKnopf(
              key: const ValueKey('push-an'),
              text: _laeuft ? '…' : 'An',
              onTap: _an,
            ),
          ],
        ],
      ),
    );
  }
}

/// Phillip's focus for the user ("Von Phillip angepasst").
class _FokusKarte extends StatelessWidget {
  const _FokusKarte({required this.fokus});
  final String fokus;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('chat-fokus'),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
    decoration: BoxDecoration(
      gradient: Klar.held,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.center_focus_strong_rounded, color: Umbau.tinte),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VON PHILLIP ANGEPASST',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  letterSpacing: 1.4,
                  color: Umbau.tinteWeich,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fokus,
                style: _tintenText.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GoldKnopf extends StatelessWidget {
  const _GoldKnopf({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: text,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: Umbau.grad,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Umbau.tinte,
          ),
        ),
      ),
    ),
  );
}

/// "Darf Phillip deine Werte sehen?" on the first send. True: share and
/// send, false: only the message, null: back to writing.
class WerteFrage extends StatelessWidget {
  const WerteFrage({super.key});

  static const _teile = [
    (Icons.spa_outlined, 'Bereiche'),
    (Icons.auto_graph_rounded, 'Muster'),
    (Icons.bedtime_outlined, 'Schlaf'),
    (Icons.center_focus_strong_rounded, 'Fokus'),
    (Icons.favorite_border_rounded, 'Ziel und Warum'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F2620),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x38E0BF7E)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Darf Phillip deine Werte sehen?',
            key: ValueKey('werte-frage'),
            style: TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Umbau.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dann muss er nicht nachfragen und sieht sofort, was los ist.',
            style: TextStyle(
              fontFamily: 'Figtree',
              fontSize: 14,
              height: 1.4,
              color: Umbau.hell,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (icon, name) in _teile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Klar.glas,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x33F0D49A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 15, color: Umbau.gold),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: Umbau.hell,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: _GoldKnopf(
              key: const ValueKey('werte-erlauben'),
              text: 'Erlauben und senden',
              onTap: () => Navigator.of(context).pop(true),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const ValueKey('werte-nur-nachricht'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Nur die Nachricht senden',
              style: TextStyle(
                fontFamily: 'Figtree',
                fontWeight: FontWeight.w600,
                color: Umbau.weich,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _komma(num x) => x.toStringAsFixed(1).replaceAll('.', ',');

String _wertText(int? w) => w == null ? '–' : '$w';

/// "Lena teilt ihre Woche ›": the values as a card in the chat, like a
/// shared post on Insta.
class WerteKarte extends StatelessWidget {
  const WerteKarte({
    super.key,
    required this.name,
    required this.werte,
    required this.onTap,
  });
  final String name;
  final GeteilteWerte werte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const ValueKey('werte-karte'),
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: Klar.held,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x33E2C48A), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Geteilte Woche' : 'Woche von $name',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Umbau.tinte,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Umbau.tinte),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final b in werte.bereiche.take(4))
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _wertText(b.wert),
                        style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Umbau.tinte,
                        ),
                      ),
                      Text(
                        _kurz(b.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 11,
                          color: Umbau.tinteWeich,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (werte.muster case final m?) ...[
            const SizedBox(height: 10),
            Text(
              'Muster: $m',
              style: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Umbau.tinte,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _kurz(String name) => switch (name) {
  'Ausstrahlung' => 'Ausstr.',
  'Fokus & Arbeit' => 'Fokus',
  'Produktivität & Fokus' => 'Fokus',
  'Business & Beruf' => 'Business',
  _ => name,
};

/// "Lenas Werte": everything at a glance, only what she shared.
class GeteilteWerteSeite extends StatefulWidget {
  const GeteilteWerteSeite({
    super.key,
    required this.dienst,
    required this.chat,
    this.onGeaendert,
  });
  final PrivatcoachDienst dienst;
  final CoachChat chat;
  final VoidCallback? onGeaendert;

  @override
  State<GeteilteWerteSeite> createState() => _GeteilteWerteSeiteState();
}

class _GeteilteWerteSeiteState extends State<GeteilteWerteSeite> {
  late String? _fokus = widget.chat.fokus;

  Future<void> _fokusAnpassen() async {
    final feld = TextEditingController(text: _fokus ?? '');
    final neu = await showDialog<String>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (c) => Dialog(
        backgroundColor: const Color(0xFF2F2620),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: Color(0x38E0BF7E)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Fokus anpassen',
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: Umbau.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Erscheint im Chat als „Von Phillip angepasst“.',
                style: Umbau.klein,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('fokus-feld'),
                controller: feld,
                autofocus: true,
                style: _text,
                cursorColor: Umbau.gold,
                decoration: InputDecoration(
                  hintText: 'z. B. Abends ab 21 Uhr Handy weg',
                  hintStyle: const TextStyle(color: Umbau.weich),
                  filled: true,
                  fillColor: Klar.glas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(color: Umbau.weich),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('fokus-speichern'),
                    onPressed: () => Navigator.of(c).pop(feld.text),
                    child: const Text(
                      'Speichern',
                      style: TextStyle(
                        color: Umbau.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (neu == null) return;
    await widget.dienst.fokusSetzen(widget.chat.userId, neu);
    setState(() => _fokus = neu.trim().isEmpty ? null : neu.trim());
    widget.onGeaendert?.call();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.chat.werte ?? const GeteilteWerte();
    final name = widget.chat.name;
    final schlaf = w.schlafSchnitt;
    return _Rahmen(
      kopf: Row(
        children: [
          const ZurueckPille(label: 'Chat'),
          const Spacer(),
          Text(name.isEmpty ? 'Werte' : '${name}s Werte', style: Umbau.titel),
          const Spacer(),
          const SizedBox(width: 60),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Einflug(
            child: Row(
              children: [
                NutzerAvatar(name: name, groesse: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Ohne Namen' : name,
                        style: Umbau.titel.copyWith(fontSize: 17),
                      ),
                      if (w.ziel case final z?)
                        Text('Ziel: $z', style: Umbau.klein),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final (i, b) in w.bereiche.indexed)
            Einflug(platz: i + 1, child: _BereichZeile(b)),
          if (schlaf != null)
            Einflug(
              platz: w.bereiche.length + 1,
              child: _GlasZeile(
                titel: 'Schlaf, 7 Nächte',
                rechts: 'im Schnitt ${_stunden(schlaf)}',
                child: _Balken(w.schlafStunden),
              ),
            ),
          if (w.muster case final m?) _GlasZeile(titel: 'Muster', unter: m),
          if (w.fokus case final f?) _GlasZeile(titel: 'Ihr Fokus', unter: f),
          if (w.warum case final x?)
            _GlasZeile(titel: 'Ihr Warum', unter: '„$x“'),
          if (_fokus case final f?)
            _GlasZeile(titel: 'Von dir angepasst', unter: f),
          const SizedBox(height: 14),
          Center(
            child: _GoldKnopf(
              key: const ValueKey('fokus-anpassen'),
              text: 'Fokus anpassen',
              onTap: _fokusAnpassen,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'Zurück zum Chat',
                style: TextStyle(color: Umbau.weich),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _stunden(double h) {
  final m = (h * 60).round();
  return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')} Std.';
}

class _GlasZeile extends StatelessWidget {
  const _GlasZeile({required this.titel, this.rechts, this.unter, this.child});
  final String titel;
  final String? rechts;
  final String? unter;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
    decoration: BoxDecoration(
      color: Klar.glas,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(titel.toUpperCase(), style: Umbau.label)),
            if (rechts != null)
              Text(rechts!, style: Umbau.klein.copyWith(color: Umbau.gold)),
          ],
        ),
        if (unter != null) ...[
          const SizedBox(height: 5),
          Text(unter!, style: _text.copyWith(fontSize: 14)),
        ],
        if (child != null) ...[const SizedBox(height: 10), child!],
      ],
    ),
  );
}

class _BereichZeile extends StatelessWidget {
  const _BereichZeile(this.b);
  final WertBereich b;

  @override
  Widget build(BuildContext context) {
    final d = b.diff;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Klar.glas,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: Umbau.titel),
                const SizedBox(height: 2),
                Text(
                  [
                    if (b.wert != null) _komma(b.wert!),
                    if (d != null && d != 0)
                      '${d > 0 ? '+' : '−'}${_komma(d.abs())}',
                  ].join(' · '),
                  style: Umbau.klein.copyWith(color: Umbau.gold),
                ),
              ],
            ),
          ),
          SizedBox(width: 110, height: 34, child: _Linie(b.woche)),
        ],
      ),
    );
  }
}

/// The week as a thin gold line.
class _Linie extends StatelessWidget {
  const _Linie(this.werte);
  final List<int?> werte;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _LinienMaler(werte));
}

class _LinienMaler extends CustomPainter {
  _LinienMaler(this.werte);
  final List<int?> werte;

  @override
  void paint(Canvas canvas, Size size) {
    final n = werte.length;
    if (n < 2) return;
    final pfad = Path();
    var an = false;
    Offset? letzter;
    for (var i = 0; i < n; i++) {
      final w = werte[i];
      if (w == null) continue;
      final p = Offset(
        size.width * i / (n - 1),
        size.height * (1 - (w.clamp(1, 10) - 1) / 9),
      );
      if (an) {
        pfad.lineTo(p.dx, p.dy);
      } else {
        pfad.moveTo(p.dx, p.dy);
        an = true;
      }
      letzter = p;
    }
    canvas.drawPath(
      pfad,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = Umbau.grad.createShader(Offset.zero & size),
    );
    if (letzter != null) {
      canvas.drawCircle(letzter, 3.2, Paint()..color = Umbau.gold);
    }
  }

  @override
  bool shouldRepaint(_LinienMaler old) => old.werte != werte;
}

/// Seven nights as small gold bars.
class _Balken extends StatelessWidget {
  const _Balken(this.stunden);
  final List<double?> stunden;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final s in stunden)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FractionallySizedBox(
                heightFactor: s == null ? .06 : (s / 10).clamp(.06, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: s == null ? null : Umbau.grad,
                    color: s == null ? Klar.glas : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Phillip's inbox: all chats like on Insta, unread with a gold dot,
/// requests with "Annehmen".
class PostEingang extends StatefulWidget {
  const PostEingang({
    super.key,
    required this.dienst,
    this.clock = DateTime.now,
    this.abholen = const Duration(seconds: 8),
    this.push = const ChatPush(),
  });
  final PrivatcoachDienst dienst;
  final ChatPush push;
  final DateTime Function() clock;
  final Duration abholen;

  @override
  State<PostEingang> createState() => _PostEingangState();
}

class _PostEingangState extends State<PostEingang> {
  List<CoachChat> _chats = const [];
  bool _nurUngelesen = false;
  bool _geladen = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _laden();
    _timer = Timer.periodic(widget.abholen, (_) => _laden());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _laden() async {
    try {
      final l = await widget.dienst.alleChats();
      if (mounted) {
        setState(() {
          _chats = l;
          _geladen = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _geladen = true);
    }
  }

  Future<void> _oeffnen(CoachChat c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatSeite(
          dienst: widget.dienst,
          chatId: c.userId,
          name: c.name,
          alsCoach: true,
          clock: widget.clock,
          push: widget.push,
        ),
      ),
    );
    await _laden();
  }

  @override
  Widget build(BuildContext context) {
    final ungelesen = _chats.where((c) => c.ungelesen > 0).length;
    final liste = _nurUngelesen
        ? _chats.where((c) => c.ungelesen > 0).toList()
        : _chats;
    return _Rahmen(
      kopf: Row(
        children: [
          const ZurueckPille(),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Deine Nachrichten',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Umbau.text,
              ),
            ),
          ),
          const PhillipAvatar(groesse: 34),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              _Reiter(
                key: const ValueKey('eingang-alle'),
                text: 'Alle',
                an: !_nurUngelesen,
                onTap: () => setState(() => _nurUngelesen = false),
              ),
              const SizedBox(width: 8),
              _Reiter(
                key: const ValueKey('eingang-ungelesen'),
                text: 'Ungelesen',
                zahl: ungelesen,
                an: _nurUngelesen,
                onTap: () => setState(() => _nurUngelesen = true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_geladen && liste.isEmpty)
            _Hinweis(
              text: _nurUngelesen
                  ? 'Alles gelesen.'
                  : 'Noch keine Nachrichten. Sobald dir jemand schreibt, '
                        'steht es hier und du bekommst eine Mitteilung.',
            ),
          for (final (i, c) in liste.indexed)
            Einflug(
              platz: i,
              child: _EingangZeile(
                chat: c,
                jetzt: widget.clock(),
                onTap: () => _oeffnen(c),
              ),
            ),
          PushHinweis(dienst: widget.dienst, push: widget.push, alsCoach: true),
        ],
      ),
    );
  }
}

class _Reiter extends StatelessWidget {
  const _Reiter({
    super.key,
    required this.text,
    required this.an,
    required this.onTap,
    this.zahl = 0,
  });
  final String text;
  final bool an;
  final int zahl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: an ? Umbau.grad : null,
        color: an ? null : Klar.glas,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Figtree',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: an ? Umbau.tinte : Umbau.hell,
            ),
          ),
          if (zahl > 0) ...[
            const SizedBox(width: 6),
            Text(
              '$zahl',
              style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: an ? Umbau.tinte : Umbau.gold,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _EingangZeile extends StatelessWidget {
  const _EingangZeile({
    required this.chat,
    required this.jetzt,
    required this.onTap,
  });
  final CoachChat chat;
  final DateTime jetzt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = chat.letzte;
    final neu = chat.ungelesen > 0;
    final vorschau = n == null
        ? ''
        : n.audio != null
        ? 'Sprachnachricht · ${dauerText(n.sekunden ?? 0)}'
        : n.vonCoach
        ? 'Du: ${n.text}'
        : n.text;
    return GestureDetector(
      key: ValueKey('eingang-${chat.userId}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            NutzerAvatar(name: chat.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          chat.name.isEmpty ? 'Ohne Namen' : chat.name,
                          overflow: TextOverflow.ellipsis,
                          style: Umbau.titel.copyWith(
                            fontWeight: neu ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (chat.status == ChatStatus.anfrage) ...[
                        const SizedBox(width: 8),
                        const KlarPille('Anfrage'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vorschau,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Umbau.klein.copyWith(
                      fontSize: 13,
                      color: neu ? Umbau.text : const Color(0xFFCDBB9D),
                      fontWeight: neu ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (n != null)
                  Text(chatZeit(n.erstellt, jetzt), style: Umbau.klein),
                const SizedBox(height: 6),
                if (neu)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: Umbau.grad,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
