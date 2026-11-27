import 'package:flutter/material.dart';

/// SonLokma tasarım token'ları. Kaynak: docs/design/tokens.json (PR #25).
@immutable
class AppPalette {
  const AppPalette({
    required this.cream,
    required this.olive,
    required this.brick,
    required this.kraft,
    required this.receipt,
    required this.oliveMuted,
  });

  /// Arka plan.
  final Color cream;

  /// Ana metin.
  final Color olive;

  /// Ana eylem (düğme, vurgu).
  final Color brick;

  /// Kraft yüzeyler, damgalar.
  final Color kraft;

  /// Fiş / kart yüzeyi.
  final Color receipt;

  /// İkincil metin.
  final Color oliveMuted;

  static const light = AppPalette(
    cream: Color(0xFFF6EFE2),
    olive: Color(0xFF3B3F22),
    brick: Color(0xFFB4532A),
    kraft: Color(0xFFD9BE91),
    receipt: Color(0xFFFFFDF8),
    oliveMuted: Color(0xFF6B6E52),
  );

  static const dark = AppPalette(
    cream: Color(0xFF1E1C16),
    olive: Color(0xFFECE4D2),
    brick: Color(0xFFD9714A),
    kraft: Color(0xFF5A4A30),
    receipt: Color(0xFF2A2820),
    oliveMuted: Color(0xFFB7AE98),
  );

  static AppPalette of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// 8 px ızgara ve bileşen ölçüleri.
abstract final class AppSizes {
  static const double grid = 8;
  static const double space1 = grid;
  static const double space2 = grid * 2;
  static const double space3 = grid * 3;
  static const double space4 = grid * 4;
  static const double buttonHeight = 52;
  static const double radius = 12;
}

/// Yazı tipi aileleri.
abstract final class AppFonts {
  static const display = 'Bricolage Grotesque';
  static const body = 'Inter';
  static const mono = 'IBM Plex Mono';
}
