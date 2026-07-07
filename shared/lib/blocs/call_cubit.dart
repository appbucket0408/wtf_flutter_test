import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/app_user.dart';
import '../models/room_meta.dart';
import '../models/session_log.dart';
import '../services/call_service.dart';
import '../services/log_service.dart';
import '../utils/app_exception.dart';
import '../utils/validators.dart';
import '../utils/wtf_logger.dart';

sealed class CallState {
  const CallState();
}

class CallIdle extends CallState {
  const CallIdle();
}

/// Pre-join device check: local preview running.
class CallPreviewing extends CallState {
  final bool micOn;
  final bool camOn;
  const CallPreviewing({this.micOn = true, this.camOn = true});

  CallPreviewing copyWith({bool? micOn, bool? camOn}) =>
      CallPreviewing(micOn: micOn ?? this.micOn, camOn: camOn ?? this.camOn);
}

class CallJoining extends CallState {
  const CallJoining();
}

class CallInRoom extends CallState {
  final int? remoteUid; // 1:1 call → at most one peer tile
  final bool micOn;
  final bool camOn;
  final bool reconnecting;
  final bool peerLeft;

  const CallInRoom({
    this.remoteUid,
    this.micOn = true,
    this.camOn = true,
    this.reconnecting = false,
    this.peerLeft = false,
  });

  CallInRoom copyWith({
    int? remoteUid,
    bool clearRemote = false,
    bool? micOn,
    bool? camOn,
    bool? reconnecting,
    bool? peerLeft,
  }) =>
      CallInRoom(
        remoteUid: clearRemote ? null : (remoteUid ?? this.remoteUid),
        micOn: micOn ?? this.micOn,
        camOn: camOn ?? this.camOn,
        reconnecting: reconnecting ?? this.reconnecting,
        peerLeft: peerLeft ?? this.peerLeft,
      );
}

class CallEnded extends CallState {
  final SessionLog log;
  const CallEnded(this.log);
}

class CallFailed extends CallState {
  final String message;
  const CallFailed(this.message);
}

/// Full call lifecycle (spec §3D): permissions → preview → join →
/// in-call controls/resilience → leave → SessionLog write.
class CallCubit extends Cubit<CallState> {
  final AgoraCallService _call;
  final LogService _logs;
  final AppUser me;
  final RoomMeta room;

  DateTime? _joinedAt;
  bool _tokenRetryDone = false;

  CallCubit({
    required AgoraCallService call,
    required LogService logs,
    required this.me,
    required this.room,
  })  : _call = call,
        _logs = logs,
        super(const CallIdle());

  String get _role =>
      me.role == UserRole.trainer ? room.roleTrainer : room.roleMember;

  RtcEngineWrapper get engineWrapper => RtcEngineWrapper(_call);

  Future<void> startDeviceCheck() async {
    try {
      await _call.ensurePermissions();
      final creds = await _call.fetchCredentials(
          userId: me.id, role: _role, channelId: room.channelId);
      await _call.initEngine(
        creds.appId,
        CallEvents(
          onJoined: () {
            _joinedAt = DateTime.now();
            emit(const CallInRoom());
          },
          onPeerJoined: (uid) {
            if (state case final CallInRoom s) {
              emit(s.copyWith(remoteUid: uid, peerLeft: false));
            }
          },
          onPeerLeft: (uid) {
            if (state case final CallInRoom s) {
              emit(s.copyWith(clearRemote: true, peerLeft: true));
            }
          },
          onConnectionChanged: (reconnecting) {
            if (state case final CallInRoom s) {
              emit(s.copyWith(reconnecting: reconnecting));
            }
          },
          onError: _onEngineError,
        ),
      );
      await _call.startPreview();
      emit(const CallPreviewing());
    } on AppException catch (e) {
      emit(CallFailed(e.userMessage));
    }
  }

  void _onEngineError(String message) {
    // Token expiry edge case: re-fetch once and retry the join.
    if (!_tokenRetryDone &&
        message.toLowerCase().contains('token') &&
        state is CallJoining) {
      _tokenRetryDone = true;
      WtfLog.d(LogTag.rtc, 'token error → refetch and retry');
      join();
    }
  }

  Future<void> toggleMic() async {
    switch (state) {
      case final CallPreviewing s:
        await _call.setMicEnabled(!s.micOn);
        emit(s.copyWith(micOn: !s.micOn));
      case final CallInRoom s:
        await _call.setMicEnabled(!s.micOn);
        emit(s.copyWith(micOn: !s.micOn));
      default:
    }
  }

  Future<void> toggleCam() async {
    switch (state) {
      case final CallPreviewing s:
        await _call.setCamEnabled(!s.camOn);
        emit(s.copyWith(camOn: !s.camOn));
      case final CallInRoom s:
        await _call.setCamEnabled(!s.camOn);
        emit(s.copyWith(camOn: !s.camOn));
      default:
    }
  }

  Future<void> flipCamera() => _call.flipCamera();

  Future<void> join() async {
    emit(const CallJoining());
    try {
      final creds = await _call.fetchCredentials(
          userId: me.id, role: _role, channelId: room.channelId);
      await _call.join(
          token: creds.token, channelId: room.channelId, uid: creds.uid);
      // onJoined callback emits CallInRoom.
    } on AppException catch (e) {
      emit(CallFailed(e.userMessage));
    }
  }

  /// Leave and persist the SessionLog (spec: auto write on end).
  Future<void> endCall() async {
    final started = _joinedAt ?? DateTime.now();
    final ended = DateTime.now();
    await _call.leave();

    final log = SessionLog(
      id: room.callRequestId,
      memberId: me.role == UserRole.member ? me.id : _peerIdFor(UserRole.member),
      trainerId:
          me.role == UserRole.trainer ? me.id : _peerIdFor(UserRole.trainer),
      startedAt: started,
      endedAt: ended,
      durationSec: durationSec(started, ended),
    );
    try {
      await _logs.create(log);
    } on AppException catch (e) {
      WtfLog.d(LogTag.rtc, 'session log write failed: ${e.raw}');
    }
    emit(CallEnded(log));
  }

  String _peerIdFor(UserRole role) {
    // Seeded 1:1 pairing: the counterpart is always the other seed user.
    return role == UserRole.member ? 'member_dk' : 'trainer_aarav';
  }

  Future<void> dismiss() async {
    await _call.leave();
    emit(const CallIdle());
  }
}

/// Thin wrapper so screens can build AgoraVideoView widgets without
/// importing the SDK service internals.
class RtcEngineWrapper {
  final AgoraCallService service;
  const RtcEngineWrapper(this.service);
}
