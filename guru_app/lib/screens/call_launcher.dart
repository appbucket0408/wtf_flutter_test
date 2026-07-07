import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../main.dart';

/// Opens the call flow for an approved request (guru side) and shows
/// the rate-session sheet when the call ends (spec §3D post-call).
Future<void> launchCall(
    BuildContext context, AppUser me, CallRequest request) async {
  final room = await scheduleService.roomFor(request.id);
  if (room == null) {
    await AppToast.error(AppStrings.genericError);
    return;
  }
  final trainers = await authService.seededTrainers();
  final peer = trainers.firstWhere(
    (t) => t.id == request.trainerId,
    orElse: () => trainers.first,
  );
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => CallScreen(
      me: me,
      peer: peer,
      room: room,
      roleColor: AppColors.guruPrimary,
      logService: logService,
      callService: callService,
      onEnded: (callContext, ended) => _showRateSheet(callContext, ended),
    ),
  ));
}

Future<void> _showRateSheet(BuildContext context, CallEnded ended) async {
  var rating = 5;
  final noteController = TextEditingController();
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
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.rateSession, style: AppTextStyles.h2),
            const SizedBox(height: Gap.s16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 36,
                    color: AppColors.warning,
                    icon: Icon(i <= rating ? Icons.star : Icons.star_border),
                    onPressed: () => setSheetState(() => rating = i),
                  ),
              ],
            ),
            const SizedBox(height: Gap.s8),
            TextField(
              controller: noteController,
              maxLength: 140,
              decoration: const InputDecoration(hintText: AppStrings.addNote),
            ),
            const SizedBox(height: Gap.s8),
            ElevatedButton(
              onPressed: () async {
                await logService.update(ended.log.copyWith(
                  rating: rating,
                  memberNotes: noteController.text.trim(),
                ));
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                await AppToast.show(AppStrings.sessionEnded);
              },
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    ),
  );
  // Leave the (now black) call screen after the sheet closes.
  if (context.mounted) Navigator.of(context).pop();
}
