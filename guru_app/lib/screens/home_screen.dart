import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import 'call_launcher.dart';
import 'chat_entry.dart';
import 'schedule_screen.dart';

/// Guru home (spec §3A): 3 cards — Chat with Trainer, Schedule Call,
/// My Sessions — plus the Upcoming Calls join banner (spec §3D).
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  Widget _card(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.s16, vertical: Gap.s8),
        leading: CircleAvatar(
          backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.guruPrimary),
        ),
        title: Text(title, style: AppTextStyles.body),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${AppStrings.memberBadge} • ${user.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.s16),
            child: CircleAvatar(
              backgroundColor: AppColors.guruPrimary,
              foregroundColor: AppColors.white,
              child: Text(user.name.substring(0, 1)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Gap.s16),
        children: [
          UpcomingCallBanner(
            approvedStream: scheduleService.watchApproved('memberId', user.id),
            roleColor: AppColors.guruPrimary,
            onJoin: (request) => launchCall(context, user, request),
          ),
          const SizedBox(height: Gap.s8),
          _card(context, Icons.chat_bubble_outline, AppStrings.chatWithTrainer,
              () => _push(
                  context,
                  ChatEntry(
                      me: user,
                      authService: authService,
                      chatService: chatService))),
          const SizedBox(height: Gap.s8),
          _card(context, Icons.calendar_month_outlined, AppStrings.scheduleCall,
              () => _push(context,
                  ScheduleScreen(me: user, scheduleService: scheduleService))),
          const SizedBox(height: Gap.s8),
          _card(
              context,
              Icons.history,
              AppStrings.mySessions,
              () => _push(
                  context,
                  SessionsScreen(
                    me: user,
                    logService: logService,
                    roleColor: AppColors.guruPrimary,
                    onScheduleFirst: () => _push(
                        context,
                        ScheduleScreen(
                            me: user, scheduleService: scheduleService)),
                  ))),
        ],
      ),
    );
  }
}
