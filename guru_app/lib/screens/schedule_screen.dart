import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wtf_shared/wtf_shared.dart';

import '../blocs/schedule_cubit.dart';

/// Spec §3C: calendar strip (next 3 days) + 30-min slot chips + note
/// (≤140) + Request Call CTA, with My Requests list below.
class ScheduleScreen extends StatelessWidget {
  final AppUser me;
  final ScheduleService scheduleService;

  const ScheduleScreen(
      {super.key, required this.me, required this.scheduleService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduleCubit(schedule: scheduleService, me: me),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<DateTime> _slotsFor(DateTime day) => [
        for (var h = 6; h <= 21; h++)
          for (final m in const [0, 30])
            DateTime(day.year, day.month, day.day, h, m),
      ];

  Future<void> _submit(BuildContext context) async {
    final error = await context.read<ScheduleCubit>().submit();
    if (error != null) {
      await AppToast.error(error);
    } else {
      _noteController.clear();
      await AppToast.show(AppStrings.requestSent);
    }
  }

  Color _statusColor(CallStatus s) => switch (s) {
        CallStatus.pending => AppColors.warning,
        CallStatus.approved => AppColors.success,
        CallStatus.declined || CallStatus.cancelled => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [for (var i = 0; i < 3; i++) now.add(Duration(days: i))];

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.scheduleCall)),
      body: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          final cubit = context.read<ScheduleCubit>();
          return ListView(
            padding: const EdgeInsets.all(Gap.s16),
            children: [
              // Day strip (next 3 days)
              Row(
                children: [
                  for (final d in days)
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.s8),
                      child: ChoiceChip(
                        label: Text(DateFormat('EEE d').format(d)),
                        selected: DateUtils.isSameDay(state.day, d),
                        onSelected: (_) => cubit.pickDay(d),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              Text(AppStrings.pickSlot, style: AppTextStyles.h2),
              const SizedBox(height: Gap.s8),
              Wrap(
                spacing: Gap.s8,
                runSpacing: Gap.s8,
                children: [
                  for (final slot in _slotsFor(state.day))
                    ChoiceChip(
                      label: Text(DateFormat('h:mm a').format(slot)),
                      selected: state.slot == slot,
                      onSelected: slot.isAfter(now)
                          ? (_) => cubit.pickSlot(slot)
                          : null, // past slots disabled
                    ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              TextField(
                controller: _noteController,
                maxLength: 140,
                maxLines: 2,
                decoration:
                    const InputDecoration(hintText: AppStrings.noteHint),
                onChanged: cubit.setNote,
              ),
              const SizedBox(height: Gap.s8),
              ElevatedButton(
                onPressed: state.submitting ? null : () => _submit(context),
                child: state.submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text(AppStrings.requestCall),
              ),
              const SizedBox(height: Gap.s24),
              Text(AppStrings.myRequests, style: AppTextStyles.h2),
              const SizedBox(height: Gap.s8),
              if (state.myRequests.isEmpty)
                const EmptyState(
                    icon: Icons.pending_actions,
                    title: AppStrings.emptySessions),
              for (final r in state.myRequests)
                Card(
                  child: ListTile(
                    title: Text(
                      DateFormat('EEE d MMM • h:mm a').format(r.scheduledFor),
                      style: AppTextStyles.body,
                    ),
                    subtitle: Text(
                      r.status == CallStatus.pending
                          ? AppStrings.pendingApprovalBy('Aarav')
                          : r.status == CallStatus.declined
                              ? AppStrings.declined(r.declineReason ?? '—')
                              : r.note,
                      style: AppTextStyles.caption,
                    ),
                    trailing: Chip(
                      label: Text(
                        r.status.name,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.white),
                      ),
                      backgroundColor: _statusColor(r.status),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
