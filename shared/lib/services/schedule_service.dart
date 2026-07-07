import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../api/api_service_interface.dart';
import '../models/call_request.dart';
import '../models/room_meta.dart';
import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import '../utils/wtf_logger.dart';
import 'auth_service.dart';
import 'chat_service.dart';

abstract class ScheduleService {
  Stream<List<CallRequest>> watchForMember(String memberId);
  Stream<List<CallRequest>> watchPendingForTrainer(String trainerId);

  /// Approved future calls for the upcoming-calls banner (either role).
  Stream<List<CallRequest>> watchApproved(String field, String userId);

  /// Approved requests on [day] — input for the conflict check.
  Future<List<CallRequest>> approvedOn(DateTime day);

  Future<void> create(CallRequest r);

  /// Creates the 100ms room, stores RoomMeta, flips status and posts the
  /// system message "Call approved for {date} {time}." into the chat.
  Future<void> approve(CallRequest r);

  Future<void> decline(CallRequest r, String reason);
  Future<RoomMeta?> roomFor(String callRequestId);
}

class FirebaseScheduleService implements ScheduleService {
  final FirebaseFirestore _db;
  final ApiServiceInterface _api;
  final ChatService _chat;

  FirebaseScheduleService({
    required ApiServiceInterface api,
    required ChatService chat,
    FirebaseFirestore? db,
  })  : _api = api,
        _chat = chat,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('callRequests');
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _db.collection('rooms');

  List<CallRequest> _fromSnap(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => CallRequest.fromMap(d.data())).toList();

  @override
  Stream<List<CallRequest>> watchForMember(String memberId) => _requests
      .where('memberId', isEqualTo: memberId)
      .orderBy('requestedAt', descending: true)
      .snapshots()
      .map(_fromSnap);

  @override
  Stream<List<CallRequest>> watchPendingForTrainer(String trainerId) =>
      _requests
          .where('trainerId', isEqualTo: trainerId)
          .where('status', isEqualTo: CallStatus.pending.name)
          .snapshots()
          .map(_fromSnap);

  @override
  Stream<List<CallRequest>> watchApproved(String field, String userId) =>
      _requests
          .where(field, isEqualTo: userId)
          .where('status', isEqualTo: CallStatus.approved.name)
          .snapshots()
          .map(_fromSnap);

  @override
  Future<List<CallRequest>> approvedOn(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _requests
        .where('status', isEqualTo: CallStatus.approved.name)
        .get();
    return _fromSnap(snap)
        .where((r) =>
            r.scheduledFor.isAfter(start.subtract(const Duration(seconds: 1))) &&
            r.scheduledFor.isBefore(end))
        .toList();
  }

  @override
  Future<void> create(CallRequest r) async {
    try {
      await _requests.doc(r.id).set(r.toMap());
      WtfLog.d(LogTag.schedule, 'request ${r.id} for ${r.scheduledFor}');
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<void> approve(CallRequest r) async {
    try {
      // Idempotent by name — safe to retry.
      final channelId = await _api.createRoom('call-${r.id}');
      final meta = RoomMeta(
        id: r.id,
        callRequestId: r.id,
        channelId: channelId,
        roleMember: 'member',
        roleTrainer: 'trainer',
      );
      final batch = _db.batch();
      batch.set(_rooms.doc(meta.id), meta.toMap());
      batch.update(
          _requests.doc(r.id), {'status': CallStatus.approved.name});
      await batch.commit();

      final date = DateFormat('d MMM').format(r.scheduledFor);
      final time = DateFormat('h:mm a').format(r.scheduledFor);
      await _chat.sendSystem(
        SeedIds.chatId(r.memberId, r.trainerId),
        AppStrings.approved(date, time),
      );
      WtfLog.d(LogTag.schedule, 'approved ${r.id} → channel $channelId');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<void> decline(CallRequest r, String reason) async {
    try {
      await _requests.doc(r.id).update({
        'status': CallStatus.declined.name,
        'declineReason': reason,
      });
      await _chat.sendSystem(
        SeedIds.chatId(r.memberId, r.trainerId),
        AppStrings.declined(reason),
      );
      WtfLog.d(LogTag.schedule, 'declined ${r.id}: $reason');
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<RoomMeta?> roomFor(String callRequestId) async {
    final doc = await _rooms.doc(callRequestId).get();
    final data = doc.data();
    return data == null ? null : RoomMeta.fromMap(data);
  }
}
