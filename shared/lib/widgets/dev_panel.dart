import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/wtf_logger.dart';

/// In-app debug banner (spec §8): floating "⋮" button that opens a
/// bottom sheet with env (masked), build info and the last 20 logs.
///
/// Wrap any screen subtree: `DevPanel(appName: 'Guru', child: ...)`.
class DevPanel extends StatelessWidget {
  final String appName;
  final Map<String, String> env;
  final Widget child;

  const DevPanel({
    super.key,
    required this.appName,
    required this.env,
    required this.child,
  });

  static String _maskValue(String v) =>
      v.length <= 4 ? '••••' : '${v.substring(0, 2)}••••${v.substring(v.length - 2)}';

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Gap.s16),
        child: ListView(
          children: [
            Text('DevPanel — $appName', style: AppTextStyles.h2),
            const SizedBox(height: Gap.s8),
            Text('Build: debug • Flutter 3.41 • ${DateTime.now().toIso8601String().substring(0, 10)}',
                style: AppTextStyles.caption),
            const SizedBox(height: Gap.s16),
            Text('Env (masked)', style: AppTextStyles.bodySmall),
            for (final e in env.entries)
              Text('${e.key}=${_maskValue(e.value)}',
                  style: AppTextStyles.caption),
            const SizedBox(height: Gap.s16),
            Text('Last ${WtfLog.recent.length} logs', style: AppTextStyles.bodySmall),
            for (final entry in WtfLog.recent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Gap.s4),
                child: Text(entry.toString(), style: AppTextStyles.caption),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: Gap.s8,
          bottom: 96,
          child: SafeArea(
            child: FloatingActionButton.small(
              heroTag: 'devpanel',
              backgroundColor: AppColors.grey700,
              foregroundColor: AppColors.white,
              onPressed: () => _open(context),
              child: const Icon(Icons.more_vert),
            ),
          ),
        ),
      ],
    );
  }
}
