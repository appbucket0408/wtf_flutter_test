import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Every text style in the project lives here — no TextStyle literals in UI code.
/// Spec §4: H1 24sp, H2 20sp, Body 14–16sp; semi-bold titles, regular body.
abstract final class AppTextStyles {
  static const h1 = TextStyle(
      fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.grey900);
  static const h2 = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.grey900);
  static const body = TextStyle(
      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.grey900);
  static const bodySmall = TextStyle(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.grey700);
  static const caption = TextStyle(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.grey500);
  static const button = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
}

/// 8pt spacing system (spec §4).
abstract final class Gap {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
}
