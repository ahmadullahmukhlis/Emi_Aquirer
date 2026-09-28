import 'package:flutter/material.dart';
import 'package:afpay_ui/afpay_ui.dart';

abstract final class PosColors {
  static const ink = AppColors.ink;
  static const accent = AppColors.primary;
  static const background = AppColors.background;
  static const soft = AppColors.soft;
}

abstract final class PosTheme {
  static ThemeData get light => AppTheme.light;
}
