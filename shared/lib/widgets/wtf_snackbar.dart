import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';

/// Error surfacing (spec §8): human copy + "Copy error" action that puts
/// the raw error on the clipboard for bug reports.
void showWtfError(BuildContext context, String human, String raw) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(human),
      backgroundColor: AppColors.error,
      action: SnackBarAction(
        label: AppStrings.copyError,
        textColor: AppColors.white,
        onPressed: () => Clipboard.setData(ClipboardData(text: raw)),
      ),
    ),
  );
}
