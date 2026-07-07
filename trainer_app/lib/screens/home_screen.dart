import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';
import 'call_launcher.dart';
import 'chat_list_screen.dart';
import 'members_screen.dart';
import 'requests_screen.dart';

/// Trainer home (spec §3A): 4 tiles — Members, Chats, Requests,
/// Sessions — plus the Upcoming Calls join banner (spec §3D).
class HomeScreen extends StatelessWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  Widget _tile(BuildContext context, IconData icon, String title,
      VoidCallback onTap) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.s16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppColors.trainerPrimary.withValues(alpha: 0.1),
                child: Icon(icon, color: AppColors.trainerPrimary),
              ),
              const SizedBox(height: Gap.s8),
              Text(title, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${AppStrings.trainerBadge} • ${user.name.split(' ').first}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Gap.s16),
            child: CircleAvatar(
              backgroundColor: AppColors.trainerPrimary,
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
            approvedStream:
                scheduleService.watchApproved('trainerId', user.id),
            roleColor: AppColors.trainerPrimary,
            onJoin: (request) => launchCall(context, user, request),
          ),
          const SizedBox(height: Gap.s8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: Gap.s16,
            crossAxisSpacing: Gap.s16,
            children: [
              _tile(context, Icons.group_outlined, AppStrings.members,
                  () => _push(context,
                      MembersScreen(me: user, authService: authService))),
              _tile(
                  context,
                  Icons.chat_bubble_outline,
                  AppStrings.chats,
                  () => _push(
                      context,
                      ChatListScreen(
                          me: user,
                          chatService: chatService,
                          authService: authService))),
              _tile(
                  context,
                  Icons.pending_actions,
                  AppStrings.requests,
                  () => _push(
                      context,
                      RequestsScreen(
                          me: user, scheduleService: scheduleService))),
              _tile(
                  context,
                  Icons.history,
                  AppStrings.sessions,
                  () => _push(
                      context,
                      SessionsScreen(
                        me: user,
                        logService: logService,
                        roleColor: AppColors.trainerPrimary,
                      ))),
            ],
          ),
        ],
      ),
    );
  }
}
