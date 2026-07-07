import '../models/call_request.dart';
import 'app_strings.dart';

/// Returns an error message when [slot] is not strictly in the future.
String? validateScheduleTime(DateTime slot, DateTime now) =>
    slot.isAfter(now) ? null : AppStrings.schedulePastError;

/// Returns an error message when [slot] collides with an already
/// approved request. Pending/declined/cancelled requests never conflict.
String? checkSlotConflict(DateTime slot, List<CallRequest> existing) =>
    existing.any((r) =>
            r.status == CallStatus.approved && r.scheduledFor == slot)
        ? AppStrings.slotConflict
        : null;

/// Whole-second duration between [start] and [end].
int durationSec(DateTime start, DateTime end) =>
    end.difference(start).inSeconds;

/// Returns an error message when [note] exceeds 140 characters.
String? validateNote(String note) =>
    note.length > 140 ? AppStrings.noteTooLong : null;
