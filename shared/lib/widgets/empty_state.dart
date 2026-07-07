import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Shared empty-state placeholder: icon illustration + title + optional CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.grey100,
              child: Icon(icon, size: 40, color: AppColors.grey500),
            ),
            const SizedBox(height: Gap.s16),
            Text(title,
                style: AppTextStyles.body, textAlign: TextAlign.center),
            if (ctaLabel != null) ...[
              const SizedBox(height: Gap.s16),
              FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
