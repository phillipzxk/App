import 'package:flutter/material.dart';

/// Colours and text styles of the approved onboarding mockup
/// (https://claude.ai/artifact/JdmD7NVMayHub5fh3MN9Xn).
abstract final class CoachStyle {
  static const teal = Color(0xFF1F8F7A);
  static const tealDeep = Color(0xFF0F3D35);
  static const gold = Color(0xFFE8B04B);
  static const ink = Color(0xFFF3F7F5);
  static const inkSoft = Color(0xFFB8CBC5);

  static const questionBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, 0.7],
    colors: [teal, tealDeep],
  );

  static const summaryBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, 0.55, 1],
    colors: [Color(0xFF2B5A4F), tealDeep, Color(0xFF3A2F12)],
  );

  static const label = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 12,
    letterSpacing: 1,
    color: inkSoft,
  );

  static const question = TextStyle(
    fontFamily: 'Fraunces',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.3,
    color: ink,
  );

  static const body = TextStyle(
    fontFamily: 'Figtree',
    fontSize: 16,
    height: 1.55,
    color: ink,
  );
}
