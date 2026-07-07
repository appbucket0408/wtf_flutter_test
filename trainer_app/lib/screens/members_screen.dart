import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

/// Basic CRM list (spec core modules): members assigned to this trainer.
class MembersScreen extends StatelessWidget {
  final AppUser me;
  final AuthService authService;

  const MembersScreen({super.key, required this.me, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.members)),
      body: FutureBuilder<List<AppUser>>(
        future: authService.membersOf(me.id),
        builder: (context, snap) {
          if (snap.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: AppStrings.genericError,
              ctaLabel: AppStrings.retry,
              onCta: () => (context as Element).markNeedsBuild(),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final members = snap.data!;
          if (members.isEmpty) {
            return const EmptyState(
                icon: Icons.group_outlined, title: AppStrings.emptySessions);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Gap.s16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.s8),
            itemBuilder: (context, i) {
              final m = members[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.guruPrimary,
                    foregroundColor: AppColors.white,
                    child: Text(m.name.substring(0, 1)),
                  ),
                  title: Text(m.name, style: AppTextStyles.body),
                  subtitle: Text(m.email, style: AppTextStyles.caption),
                  trailing:
                      Text(AppStrings.memberBadge, style: AppTextStyles.caption),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
