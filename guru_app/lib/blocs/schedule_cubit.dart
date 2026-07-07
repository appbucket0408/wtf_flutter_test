import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

class ScheduleState {
  final DateTime day;
  final DateTime? slot;
  final String note;
  final bool submitting;
  final List<CallRequest> myRequests;

  const ScheduleState({
    required this.day,
    this.slot,
    this.note = '',
    this.submitting = false,
    this.myRequests = const [],
  });

  ScheduleState copyWith({
    DateTime? day,
    DateTime? slot,
    bool clearSlot = false,
    String? note,
    bool? submitting,
    List<CallRequest>? myRequests,
  }) =>
      ScheduleState(
        day: day ?? this.day,
        slot: clearSlot ? null : (slot ?? this.slot),
        note: note ?? this.note,
        submitting: submitting ?? this.submitting,
        myRequests: myRequests ?? this.myRequests,
      );
}

/// Guru scheduling (spec §3C): pick a day (next 3), a 30-min slot, add a
/// note (≤140) and request a call. Also streams DK's own requests.
class ScheduleCubit extends Cubit<ScheduleState> {
  final ScheduleService _schedule;
  final AppUser me;
  StreamSubscription<List<CallRequest>>? _sub;

  ScheduleCubit({required ScheduleService schedule, required this.me})
      : _schedule = schedule,
        super(ScheduleState(day: DateTime.now())) {
    _sub = _schedule
        .watchForMember(me.id)
        .listen((reqs) => emit(state.copyWith(myRequests: reqs)));
  }

  void pickDay(DateTime day) => emit(state.copyWith(day: day, clearSlot: true));
  void pickSlot(DateTime slot) => emit(state.copyWith(slot: slot));
  void setNote(String note) => emit(state.copyWith(note: note));

  /// Returns null on success, or the validation/user error message.
  Future<String?> submit() async {
    final slot = state.slot;
    if (slot == null) return AppStrings.pickSlot;

    final timeError = validateScheduleTime(slot, DateTime.now());
    if (timeError != null) return timeError;

    final noteError = validateNote(state.note);
    if (noteError != null) return noteError;

    emit(state.copyWith(submitting: true));
    try {
      final approved = await _schedule.approvedOn(slot);
      final conflict = checkSlotConflict(slot, approved);
      if (conflict != null) return conflict;

      await _schedule.create(CallRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        memberId: me.id,
        trainerId: me.assignedTrainerId ?? SeedIds.trainerAarav,
        requestedAt: DateTime.now(),
        scheduledFor: slot,
        note: state.note.trim(),
        status: CallStatus.pending,
      ));
      emit(state.copyWith(clearSlot: true, note: ''));
      return null;
    } on AppException catch (e) {
      return e.userMessage;
    } finally {
      emit(state.copyWith(submitting: false));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
