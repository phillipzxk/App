import 'package:flutter/material.dart';

/// Groundset design, decided with Phillip on 2026-10-13 (vault note
/// Umsetzung/Design.md): warm sand white, champagne gold, dark buttons with
/// gold text, Sora for headings and Figtree for text.
abstract final class CoachStyle {
  // Whole app dark with beige and gold (Phillip 2026-10-18): black-brown
  // page, slightly lighter cards with fine beige lines, beige text, gold
  // for what matters most.
  static const page = Color(0xFF110E0B);
  static const card = Color(0xFF1E1914);
  static const line = Color(0xFF3A3127);
  static const bar = Color(0xFF2F271E);
  static const gold = Color(0xFFC9A25C);
  static const goldLight = Color(0xFFE0BF7E);

  /// Beige: light accent on dark (pills, small buttons, icons).
  static const goldSoft = Color(0xFFE6D7BB);
  static const beige = goldSoft;
  static const dark = Color(0xFF0D0B08);
  static const ink = Color(0xFFEFE5D2);
  static const inkSoft = Color(0xFFA99B84);
  static const onDark = ink;

  /// Background of a picked answer: dark with a touch of gold.
  static const selectedFill = Color(0xFF33291B);

  /// Fine beige line around cards.
  static const hairline = Color(0x33D9C7A7);

  /// Muted beige for small headings.
  static const beigeLabel = Color(0xFFCDBB98);

  static const edge = Color(0xFF2E261C);
  static const goldEdge = Color(0xFF6B5535);
  static const cardBright = Color(0xFF1B1611);
  static const edgeStrong = Color(0xFF3A3127);

  static const cardShadowStrong = [
    BoxShadow(color: Color(0x66000000), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const darkShadow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const goldShadow = [
    BoxShadow(color: Color(0x26D6AA5E), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF221B15), Color(0xFF17130F)],
  );

  static const coachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2118), Color(0xFF15110D)],
  );

  static const goldCardGradient = cardGradient;

  static const reminderGradient = LinearGradient(
    colors: [Color(0xFF2A2117), Color(0xFF1B1611)],
    stops: [0, 0.7],
  );

  /// Page background: black-brown, a little lighter at the top.
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1611), Color(0xFF120F0B), Color(0xFF0D0B08)],
    stops: [0, 0.55, 1],
  );

  static const label = TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    letterSpacing: 1.4,
    color: inkSoft,
  );

  static const goldLabel = TextStyle(
    fontFamily: 'Figtree',
    fontWeight: FontWeight.w600,
    fontSize: 11.5,
    letterSpacing: 1.4,
    color: gold,
  );

  static const question = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w600,
    fontSize: 23,
    height: 1.3,
    letterSpacing: -0.2,
    color: ink,
  );

  static const title = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.2,
    letterSpacing: -0.3,
    color: ink,
  );

  static const cardTitle = TextStyle(
    fontFamily: 'Sora',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: ink,
  );

  static const body = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    height: 1.5,
    color: ink,
  );

  // Dark style with gold gradients (Phillip 2026-10-18): black-brown for
  // the daily pages (check-in, Heute), light pages stay as contrast.
  static const night = Color(0xFF120F0B);
  static const nightCard = Color(0xFF18140F);
  static const nightCardOpen = Color(0xFF231C15);
  static const nightLine = Color(0xFF2E261C);
  static const nightLineStrong = Color(0xFF3A3024);
  static const nightChip = Color(0xFF221C15);
  static const cream = Color(0xFFF3E9D6);
  static const creamSoft = Color(0xFF9A8C77);
  static const nightMuted = Color(0xFF6F6352);
  static const goldBright = Color(0xFFE0BF7E);
  static const goldInk = Color(0xFF1A140E);

  /// Black-brown page, a little lighter at the top.
  static const nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1C1611), Color(0xFF120F0B), Color(0xFF0D0B08)],
    stops: [0, 0.55, 1],
  );

  /// Soft gold shimmer in the top right corner of dark areas.
  static const nightGlow = RadialGradient(
    center: Alignment(0.8, -1.1),
    radius: 1.1,
    colors: [Color(0x47D6AA5E), Color(0x00D6AA5E)],
  );

  /// Metallic gold for picked answers, badges and the main button.
  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5DFAE), Color(0xFFD4A85E), Color(0xFF9A6D35)],
    stops: [0, 0.45, 1],
  );

  /// Gold edge of the open card.
  static const goldEdgeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0D9A6), Color(0xFF8A6330), Color(0xFF3A2E21)],
    stops: [0, 0.5, 1],
  );

  /// Gold for big headings on dark (used as a text shader).
  static const goldTextGradient = LinearGradient(
    colors: [Color(0xFFFBF1DC), Color(0xFFE6C789), Color(0xFFB8894A)],
    stops: [0, 0.6, 1],
  );

  /// Light cream for fields that should stand out on the dark page.
  static const creamGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF7F0E3), Color(0xFFE8DAC0)],
  );

  /// Softer dark brown text on cream.
  static const creamInkSoft = Color(0xFF6B5A44);

  static const goldGlow = [
    BoxShadow(color: Color(0x59D6AA5E), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const nightShadow = [
    BoxShadow(color: Color(0x80000000), blurRadius: 36, offset: Offset(0, 14)),
  ];
}
