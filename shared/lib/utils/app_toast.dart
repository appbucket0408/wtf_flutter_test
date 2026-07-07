import 'package:fluttertoast/fluttertoast.dart';

import 'app_colors.dart';

/// All toasts go through fluttertoast via these wrappers.
abstract final class AppToast {
  static Future<void> show(String msg) => Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.grey700,
        textColor: AppColors.white,
      );

  static Future<void> error(String msg) => Fluttertoast.showToast(
        msg: msg,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        toastLength: Toast.LENGTH_LONG,
      );
}
