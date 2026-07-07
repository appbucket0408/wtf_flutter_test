import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

class RequestsState {
  final List<CallRequest> pending;
  final bool loading;
  final String? actingOnId; // request currently being approved/declined

  const RequestsState({
    this.pending = const [],
    this.loading = true,
    this.actingOnId,
  });

  RequestsState copyWith({
    List<CallRequest>? pending,
    bool? loading,
    String? actingOnId,
    bool clearActing = false,
  }) =>
      RequestsState(
        pending: pending ?? this.pending,
        loading: loading ?? this.loading,
        actingOnId: clearActing ? null : (actingOnId ?? this.actingOnId),
      );
}

/// Trainer requests inbox (spec §3C): pending list with inline
/// approve (creates channel + system message) / decline (with reason).
class RequestsCubit extends Cubit<RequestsState> {
  final ScheduleService _schedule;
  final AppUser me;
  StreamSubscription<List<CallRequest>>? _sub;

  RequestsCubit({required ScheduleService schedule, required this.me})
      : _schedule = schedule,
        super(const RequestsState()) {
    _sub = _schedule.watchPendingForTrainer(me.id).listen(
        (reqs) => emit(state.copyWith(pending: reqs, loading: false)));
  }

  Future<String?> approve(CallRequest r) async {
    emit(state.copyWith(actingOnId: r.id));
    try {
      await _schedule.approve(r);
      return null;
    } on AppException catch (e) {
      return e.userMessage;
    } finally {
      emit(state.copyWith(clearActing: true));
    }
  }

  Future<String?> decline(CallRequest r, String reason) async {
    emit(state.copyWith(actingOnId: r.id));
    try {
      await _schedule.decline(r, reason);
      return null;
    } on AppException catch (e) {
      return e.userMessage;
    } finally {
      emit(state.copyWith(clearActing: true));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
