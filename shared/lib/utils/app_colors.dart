import 'package:flutter/material.dart';

/// Every color in the project lives here — no color literals in UI code.
abstract final class AppColors {
  // Brand primaries (spec §4)
  static const guruPrimary = Color(0xFF1769E0);
  static const trainerPrimary = Color(0xFFE50914);

  // Status (spec §4)
  static const success = Color(0xFF12B76A);
  static const warning = Color(0xFFF79009);
  static const error = Color(0xFFD92D20);

  // Neutral greys
  static const grey50 = Color(0xFFF9FAFB);
  static const grey100 = Color(0xFFF2F4F7);
  static const grey200 = Color(0xFFE4E7EC);
  static const grey300 = Color(0xFFD0D5DD);
  static const grey500 = Color(0xFF667085);
  static const grey700 = Color(0xFF344054);
  static const grey900 = Color(0xFF101828);

  static const white = Colors.white;

  // Chat bubbles (role colors, spec §3B)
  static const memberBubble = guruPrimary;
  static const trainerBubble = trainerPrimary;
}
