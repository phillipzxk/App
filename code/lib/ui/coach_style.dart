import 'package:flutter/material.dart';

/// Groundset design, decided with Phillip on 2026-10-13 (vault note
/// Umsetzung/Design.md): warm sand white, champagne gold, dark buttons with
/// gold text, Sora for headings and Figtree for text.
abstract final class CoachStyle {
  static const page = Color(0xFFEFE9DE);
  static const card = Color(0xFFF9F6F0);
  static const line = Color(0xFFE0D6C4);
  static const bar = Color(0xFFDED2BC);
  static const gold = Color(0xFFB08A4F);
  static const goldLight = Color(0xFFC9A86D);
  static const goldSoft = Color(0xFFF3E3C2);
  static const dark = Color(0xFF2A2620);
  static const ink = dark;
  static const inkSoft = Color(0xFF7D7466);
  static const onDark = Color(0xFFF1EBE0);

  // Depth (variant C "Ebenen", Phillip 2026-10-16): soft shadows, light
  // gradients, and a gold edge for reminder fields. Colours stay the same.
  static const edge = Color(0xFFE6DCCB);
  static const goldEdge = Color(0xFFE2CFA9);

  // More contrast between the cards (Phillip 2026-10-16): cards lighter
  // than the page, stronger edge, deeper shadow.
  static const cardBright = Color(0xFFFFFDF9);
  static const edgeStrong = Color(0xFFD9CCB4);

  static const cardShadowStrong = [
    BoxShadow(color: Color(0x142A2620), blurRadius: 4, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x1F2A2620), blurRadius: 26, offset: Offset(0, 12)),
  ];

  static const cardShadow = [
    BoxShadow(color: Color(0x0F2A2620), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x142A2620), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const darkShadow = [
    BoxShadow(color: Color(0x4D2A2620), blurRadius: 28, offset: Offset(0, 12)),
  ];

  static const goldShadow = [
    BoxShadow(color: Color(0x2EB08A4F), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCFAF6), card],
  );

  static const coachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A342B), Color(0xFF221F1A)],
  );

  static const goldCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6ECD9), Color(0xFFFDFAF4)],
    stops: [0, 0.6],
  );

  static const reminderGradient = LinearGradient(
    colors: [Color(0xFFF6ECD9), Color(0xFFFBF8F2)],
    stops: [0, 0.7],
  );

  /// Page background: a little lighter at the top, then sand white.
  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6F1E7), page],
    stops: [0, 0.3],
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
}
