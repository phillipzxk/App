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
