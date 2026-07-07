import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Three-dot typing indicator, 900ms loop (spec §3B).
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Gap.s4),
        padding:
            const EdgeInsets.symmetric(horizontal: Gap.s16, vertical: Gap.s8),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Opacity(
                    opacity: _dotOpacity(i),
                    child: const CircleAvatar(
                        radius: 3, backgroundColor: AppColors.grey500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _dotOpacity(int index) {
    final t = (_controller.value * 3 - index).clamp(0.0, 1.0);
    return 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }
}
