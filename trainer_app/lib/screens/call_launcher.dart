import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';

/// Opens the call flow for an approved request (trainer side) and shows
/// the quick-notes sheet when the call ends (spec §3D post-call).
Future<void> launchCall(
    BuildContext context, AppUser me, CallRequest request) async {
  final room = await scheduleService.roomFor(request.id);
  if (room == null) {
    await AppToast.error(AppStrings.genericError);
    return;
  }
  final members = await authService.membersOf(me.id);
  final peer = members.firstWhere(
    (m) => m.id == request.memberId,
    orElse: () => members.first,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CallScreen(
      me: me,
      peer: peer,
      room: room,
      roleColor: AppColors.trainerPrimary,
      logService: logService,
      callService: callService,
      onEnded: (callContext, ended) => _showNotesSheet(callContext, ended),
    ),
  ));
}

Future<void> _showNotesSheet(BuildContext context, CallEnded ended) async {
  final notesController = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: Gap.s24,
        right: Gap.s24,
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + Gap.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppStrings.trainerQuickNotes, style: AppTextStyles.h2),
          const SizedBox(height: Gap.s16),
          TextField(
            controller: notesController,
            maxLength: 140,
            maxLines: 2,
            decoration: const InputDecoration(hintText: AppStrings.addNote),
          ),
          const SizedBox(height: Gap.s8),
          ElevatedButton(
            onPressed: () async {
              await logService.update(ended.log
                  .copyWith(trainerNotes: notesController.text.trim()));
              if (sheetContext.mounted) {
                Navigator.of(sheetContext).pop();
              }
              await AppToast.show(AppStrings.sessionEnded);
            },
            child: const Text(AppStrings.markComplete),
          ),
        ],
      ),
    ),
  );
  if (context.mounted) Navigator.of(context).pop();
}
