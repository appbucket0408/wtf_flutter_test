import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  group('Message', () {
    test('JSON round-trip preserves all fields', () {
      final m = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 'member_dk',
        receiverId: 'trainer_aarav',
        text: 'Hi Coach 👋',
        createdAt: DateTime(2026, 7, 7, 18),
        status: MessageStatus.sent,
      );
      final restored = Message.fromMap(m.toMap());
      expect(restored.id, 'm1');
      expect(restored.chatId, 'c1');
      expect(restored.senderId, 'member_dk');
      expect(restored.receiverId, 'trainer_aarav');
      expect(restored.text, 'Hi Coach 👋');
      expect(restored.createdAt, DateTime(2026, 7, 7, 18));
      expect(restored.status, MessageStatus.sent);
    });

    test('copyWith updates status only', () {
      final m = Message(
        id: 'm1',
        chatId: 'c1',
        senderId: 's',
        receiverId: 'r',
        text: 'hello',
        createdAt: DateTime(2026, 7, 7),
        status: MessageStatus.sending,
      );
      final read = m.copyWith(status: MessageStatus.read);
      expect(read.status, MessageStatus.read);
      expect(read.text, 'hello');
    });
  });

  group('CallRequest', () {
    test('round-trip with status enum and optional declineReason', () {
      final r = CallRequest(
        id: 'r1',
        memberId: 'member_dk',
        trainerId: 'trainer_aarav',
        requestedAt: DateTime(2026, 7, 7, 12),
        scheduledFor: DateTime(2026, 7, 7, 18),
        note: 'Macros review',
        status: CallStatus.pending,
      );
      final restored = CallRequest.fromMap(r.toMap());
      expect(restored.status, CallStatus.pending);
      expect(restored.scheduledFor, DateTime(2026, 7, 7, 18));
      expect(restored.declineReason, isNull);
    });
  });

  group('AppUser', () {
    test('round-trip with role enum and optional trainer assignment', () {
      final u = AppUser(
        id: 'member_dk',
        role: UserRole.member,
        name: 'DK',
        email: 'dk@wtf.fit',
        assignedTrainerId: 'trainer_aarav',
      );
      final restored = AppUser.fromMap(u.toMap());
      expect(restored.role, UserRole.member);
      expect(restored.assignedTrainerId, 'trainer_aarav');
      expect(restored.avatarUrl, isNull);
    });
  });

  group('SessionLog', () {
    test('round-trip with optional rating and notes', () {
      final log = SessionLog(
        id: 'l1',
        memberId: 'member_dk',
        trainerId: 'trainer_aarav',
        startedAt: DateTime(2026, 7, 7, 18),
        endedAt: DateTime(2026, 7, 7, 18, 25),
        durationSec: 1500,
        rating: 5,
        memberNotes: 'Great session',
      );
      final restored = SessionLog.fromMap(log.toMap());
      expect(restored.durationSec, 1500);
      expect(restored.rating, 5);
      expect(restored.trainerNotes, isNull);
    });
  });

  group('RoomMeta', () {
    test('round-trip', () {
      final meta = RoomMeta(
        id: 'room1',
        callRequestId: 'r1',
        channelId: 'call-r1',
        roleMember: 'member',
        roleTrainer: 'trainer',
      );
      expect(RoomMeta.fromMap(meta.toMap()).channelId, 'call-r1');
    });
  });
}
