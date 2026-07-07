import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/requests_cubit.dart';

/// Spec §3C trainer flow: pending requests with DK's note,
/// Approve/Decline inline; decline opens a reason modal.
class RequestsScreen extends StatelessWidget {
  final AppUser me;
  final ScheduleService scheduleService;

  const RequestsScreen(
      {super.key, required this.me, required this.scheduleService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RequestsCubit(schedule: scheduleService, me: me),
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.requests)),
        body: BlocBuilder<RequestsCubit, RequestsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.pending.isEmpty) {
              return const EmptyState(
                icon: Icons.pending_actions,
                title: AppStrings.emptySessions,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(Gap.s16),
              itemCount: state.pending.length,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.s8),
              itemBuilder: (context, i) =>
                  _RequestCard(request: state.pending[i], state: state),
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CallRequest request;
  final RequestsState state;

  const _RequestCard({required this.request, required this.state});

  Future<void> _approve(BuildContext context) async {
    final error = await context.read<RequestsCubit>().approve(request);
    if (error != null) {
      await AppToast.error(error);
    } else {
      final date = DateFormat('d MMM').format(request.scheduledFor);
      final time = DateFormat('h:mm a').format(request.scheduledFor);
      await AppToast.show(AppStrings.approved(date, time));
    }
  }

  Future<void> _decline(BuildContext context) async {
    final cubit = context.read<RequestsCubit>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.declineReasonTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 140,
          decoration:
              const InputDecoration(hintText: AppStrings.declineReasonHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final error = await cubit.decline(request, reason);
    if (error != null) await AppToast.error(error);
  }

  @override
  Widget build(BuildContext context) {
    final acting = state.actingOnId == request.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.guruPrimary,
                  foregroundColor: AppColors.white,
                  child: Text('D'),
                ),
                const SizedBox(width: Gap.s8),
                Expanded(
                  child: Text(
                    DateFormat('EEE d MMM • h:mm a')
                        .format(request.scheduledFor),
                    style: AppTextStyles.body,
                  ),
                ),
              ],
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: Gap.s8),
              Text('“${request.note}”', style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: Gap.s16),
            if (acting)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decline(context),
                      child: const Text(AppStrings.decline),
                    ),
                  ),
                  const SizedBox(width: Gap.s8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context),
                      child: const Text(AppStrings.approve),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
