import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  final now = DateTime(2026, 7, 7, 12);

  group('validateScheduleTime', () {
    test('rejects past slot', () {
      expect(validateScheduleTime(DateTime(2026, 7, 7, 11), now), isNotNull);
    });
    test('rejects slot equal to now', () {
      expect(validateScheduleTime(now, now), isNotNull);
    });
    test('accepts future slot', () {
      expect(validateScheduleTime(DateTime(2026, 7, 7, 18), now), isNull);
    });
  });

  group('checkSlotConflict', () {
    CallRequest req(CallStatus status, DateTime slot) => CallRequest(
        id: 'r1',
        memberId: 'm',
        trainerId: 't',
        requestedAt: now,
        scheduledFor: slot,
        note: '',
        status: status);

    test('conflict when slot already approved', () {
      final existing = [req(CallStatus.approved, DateTime(2026, 7, 7, 18))];
      expect(checkSlotConflict(DateTime(2026, 7, 7, 18), existing), isNotNull);
      expect(checkSlotConflict(DateTime(2026, 7, 7, 18, 30), existing), isNull);
    });
    test('pending request is not a conflict', () {
      final existing = [req(CallStatus.pending, DateTime(2026, 7, 7, 18))];
      expect(checkSlotConflict(DateTime(2026, 7, 7, 18), existing), isNull);
    });
    test('declined request is not a conflict', () {
      final existing = [req(CallStatus.declined, DateTime(2026, 7, 7, 18))];
      expect(checkSlotConflict(DateTime(2026, 7, 7, 18), existing), isNull);
    });
  });

  group('durationSec', () {
    test('computes whole-second duration', () {
      expect(
          durationSec(DateTime(2026, 7, 7, 18), DateTime(2026, 7, 7, 18, 25, 30)),
          1530);
    });
    test('zero for equal times', () {
      expect(durationSec(now, now), 0);
    });
  });

  group('validateNote', () {
    test('accepts 140 chars', () => expect(validateNote('x' * 140), isNull));
    test('rejects 141 chars', () => expect(validateNote('x' * 141), isNotNull));
  });
}
