import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_user.dart';
import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import '../utils/wtf_logger.dart';

/// Fixed seed ids (spec: DK persona + Aarav lead trainer).
abstract final class SeedIds {
  static const trainerAarav = 'trainer_aarav';
  static const memberDk = 'member_dk';
  static String chatId(String memberId, String trainerId) =>
      '${memberId}_$trainerId';
}

abstract class AuthService {
  /// Restore the locally persisted session (Hive), if any.
  Future<AppUser?> restoreSession();

  /// Guru onboarding: create the DK member profile assigned to [trainerId].
  Future<AppUser> onboardMember({
    required String name,
    required String trainerId,
  });

  /// Trainer mock login: seeds "Aarav (Lead Trainer)" when absent.
  Future<AppUser> loginTrainer();

  /// Seeded trainers for the onboarding picker.
  Future<List<AppUser>> seededTrainers();

  /// Members assigned to [trainerId] (trainer app CRM list + chat list).
  Future<List<AppUser>> membersOf(String trainerId);

  Future<void> logout();
}

class FirebaseAuthService implements AuthService {
  final FirebaseFirestore _db;
  FirebaseAuthService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static const _authBox = 'auth';
  static const _userKey = 'currentUser';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  static const _aarav = AppUser(
    id: SeedIds.trainerAarav,
    role: UserRole.trainer,
    name: 'Aarav (Lead Trainer)',
    email: 'aarav@wtf.fit',
  );

  @override
  Future<AppUser?> restoreSession() async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_authBox);
    final raw = box.get(_userKey);
    if (raw == null) return null;
    WtfLog.d(LogTag.auth, 'session restored from Hive');
    return AppUser.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> _persist(AppUser user) async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_authBox);
    await box.put(_userKey, user.toMap());
  }

  @override
  Future<AppUser> onboardMember({
    required String name,
    required String trainerId,
  }) async {
    try {
      final user = AppUser(
        id: SeedIds.memberDk,
        role: UserRole.member,
        name: name,
        email: 'dk@wtf.fit',
        assignedTrainerId: trainerId,
      );
      await _users.doc(user.id).set(user.toMap());
      await _persist(user);
      WtfLog.d(LogTag.auth, 'member onboarded: ${user.name} → $trainerId');
      return user;
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<AppUser> loginTrainer() async {
    try {
      await _users.doc(_aarav.id).set(_aarav.toMap(), SetOptions(merge: true));
      await _persist(_aarav);
      WtfLog.d(LogTag.auth, 'trainer logged in: ${_aarav.name}');
      return _aarav;
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<List<AppUser>> seededTrainers() async {
    try {
      // Ensure Aarav exists even if the trainer app has never run.
      await _users.doc(_aarav.id).set(_aarav.toMap(), SetOptions(merge: true));
      final snap = await _users
          .where('role', isEqualTo: UserRole.trainer.name)
          .get();
      return snap.docs.map((d) => AppUser.fromMap(d.data())).toList();
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<List<AppUser>> membersOf(String trainerId) async {
    try {
      final snap = await _users
          .where('role', isEqualTo: UserRole.member.name)
          .where('assignedTrainerId', isEqualTo: trainerId)
          .get();
      return snap.docs.map((d) => AppUser.fromMap(d.data())).toList();
    } catch (e) {
      throw AppException(AppStrings.genericError, e);
    }
  }

  @override
  Future<void> logout() async {
    final box = await Hive.openBox<Map<dynamic, dynamic>>(_authBox);
    await box.delete(_userKey);
    WtfLog.d(LogTag.auth, 'logged out');
  }
}
