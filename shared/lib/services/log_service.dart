import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/session_log.dart';
import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import '../utils/wtf_logger.dart';

abstract class LogService {
  /// [field] is 'memberId' or 'trainerId' depending on the viewing role.
  Stream<List<SessionLog>> watch(String field, String userId);
  Future<void> create(SessionLog log);
  Future<void> update(SessionLog log);
}

class FirebaseLogService implements LogService {
  final FirebaseFirestore _db;
  FirebaseLogService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('sessionLogs');

  @override
  Stream<List<SessionLog>> watch(String field, String userId) => _logs
      .where(field, isEqualTo: userId)
      .orderBy('startedAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => SessionLog.fromMap(d.data())).toList());

  @override
  Future<void> create(SessionLog log) async {
    try {
      await _logs.doc(log.id).set(log.toMap());
      WtfLog.d(LogTag.rtc, 'session log ${log.id} (${log.durationSec}s)');
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<void> update(SessionLog log) async {
    try {
      await _logs.doc(log.id).set(log.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }
}
