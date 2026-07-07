import 'dart:async';

import '../models/app_user.dart';
import '../models/call_request.dart';
import '../models/message.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'schedule_service.dart';

/// Bridges Firestore streams → local notifications for one signed-in user.
/// Fires for items that arrive after start-up so opening the app doesn't
/// replay history. Started once from each app after login.
class NotificationCoordinator {
  final NotificationService _notif;
  final ChatService _chat;
  final ScheduleService _schedule;
  final AppUser me;

  final Set<String> _seenMessages = {};
  final Map<String, CallStatus> _lastRequestStatus = {};
  final Set<String> _remindersSet = {};
  bool _msgPrimed = false;
  bool _reqPrimed = false;

  StreamSubscription<List<Message>>? _msgSub;
  StreamSubscription<List<CallRequest>>? _reqSub;

  NotificationCoordinator({
    required NotificationService notif,
    required ChatService chat,
    required ScheduleService schedule,
    required this.me,
  })  : _notif = notif,
        _chat = chat,
        _schedule = schedule;

  Future<void> start({required String peerId}) async {
    await _notif.init();
    final chatId = me.role == UserRole.member
        ? '${me.id}_$peerId'
        : '${peerId}_${me.id}';

    _msgSub = _chat.watchMessages(chatId).listen(_onMessages);

    // Members watch their own requests (approval/decline alerts + reminders);
    // trainers watch incoming pending requests.
    _reqSub = (me.role == UserRole.member
            ? _schedule.watchForMember(me.id)
            : _schedule.watchPendingForTrainer(me.id))
        .listen(_onRequests);
  }

  void _onMessages(List<Message> messages) {
    for (final m in messages) {
      final isNew = !_seenMessages.contains(m.id);
      _seenMessages.add(m.id);
      // First batch just primes the seen-set so we don't replay history.
      if (!_msgPrimed || !isNew) continue;
      // Only notify for messages addressed to me, not my own echoes.
      if (m.receiverId == me.id && !m.isSystem) {
        _notif.show(id: m.id.hashCode, title: 'New message', body: m.text);
      } else if (m.isSystem && m.receiverId == me.id) {
        _notif.show(id: m.id.hashCode, title: 'WTF', body: m.text);
      }
    }
    _msgPrimed = true;
  }

  void _onRequests(List<CallRequest> requests) {
    for (final r in requests) {
      final prev = _lastRequestStatus[r.id];
      _lastRequestStatus[r.id] = r.status;

      if (_reqPrimed && me.role == UserRole.member && prev != r.status) {
        if (r.status == CallStatus.approved) {
          _notif.show(
              id: r.id.hashCode,
              title: 'Call approved',
              body: 'Your session is confirmed. Get ready!');
        } else if (r.status == CallStatus.declined) {
          _notif.show(
              id: r.id.hashCode,
              title: 'Call declined',
              body: r.declineReason ?? 'Your request was declined.');
        }
      }

      if (_reqPrimed &&
          me.role == UserRole.trainer &&
          prev == null &&
          r.status == CallStatus.pending) {
        _notif.show(
            id: r.id.hashCode,
            title: 'New call request',
            body: r.note.isEmpty ? 'A member requested a call.' : r.note);
      }

      // Schedule the 10-min-before reminder once per approved call.
      if (r.status == CallStatus.approved && !_remindersSet.contains(r.id)) {
        _remindersSet.add(r.id);
        _notif.scheduleAt(
          id: r.id.hashCode ^ 0x5EED,
          title: 'Upcoming call',
          body: 'Your session starts in 10 minutes.',
          when: r.scheduledFor.subtract(const Duration(minutes: 10)),
        );
      }
    }
    _reqPrimed = true;
  }

  Future<void> dispose() async {
    await _msgSub?.cancel();
    await _reqSub?.cancel();
  }
}
