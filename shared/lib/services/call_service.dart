import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import '../api/api_service_interface.dart';
import '../utils/app_exception.dart';
import '../utils/app_strings.dart';
import '../utils/wtf_logger.dart';

/// Callbacks surfaced to the CallBloc.
class CallEvents {
  final void Function() onJoined;
  final void Function(int remoteUid) onPeerJoined;
  final void Function(int remoteUid) onPeerLeft;
  final void Function(bool reconnecting) onConnectionChanged;
  final void Function(String message) onError;

  const CallEvents({
    required this.onJoined,
    required this.onPeerJoined,
    required this.onPeerLeft,
    required this.onConnectionChanged,
    required this.onError,
  });
}

abstract class CallService {
  Future<void> initEngine(String appId, CallEvents events);

  /// Local camera preview for the pre-join device check.
  Future<void> startPreview();

  Future<void> join({required String token, required String channelId, required int uid});
  Future<void> setMicEnabled(bool enabled);
  Future<void> setCamEnabled(bool enabled);
  Future<void> flipCamera();
  Future<void> leave();

  RtcEngine get engine;
}

/// Agora implementation (ADR #3 pivot: Agora replaces 100ms; deviation
/// documented in DECISIONS.md).
class AgoraCallService implements CallService {
  final ApiServiceInterface _api;
  RtcEngine? _engine;

  AgoraCallService({required ApiServiceInterface api}) : _api = api;

  @override
  RtcEngine get engine {
    final e = _engine;
    if (e == null) throw const AppException(AppStrings.genericError);
    return e;
  }

  /// RTC credentials via token server; re-used on token-expiry retry.
  Future<RtcCredentials> fetchCredentials({
    required String userId,
    required String role,
    required String channelId,
  }) =>
      _api.getAuthToken(userId: userId, role: role, roomId: channelId);

  Future<void> ensurePermissions() async {
    final statuses =
        await [Permission.camera, Permission.microphone].request();
    if (statuses.values.any((s) => !s.isGranted)) {
      throw const AppException(AppStrings.joinPrompt);
    }
  }

  @override
  Future<void> initEngine(String appId, CallEvents events) async {
    if (_engine != null) return;
    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        WtfLog.d(LogTag.rtc, 'joined ${connection.channelId}');
        events.onJoined();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        WtfLog.d(LogTag.rtc, 'peer joined uid=$remoteUid');
        events.onPeerJoined(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        WtfLog.d(LogTag.rtc, 'peer left uid=$remoteUid (${reason.name})');
        events.onPeerLeft(remoteUid);
      },
      onConnectionStateChanged: (connection, state, reason) {
        final reconnecting =
            state == ConnectionStateType.connectionStateReconnecting;
        WtfLog.d(LogTag.rtc, 'connection ${state.name} (${reason.name})');
        events.onConnectionChanged(reconnecting);
      },
      onError: (err, msg) {
        WtfLog.d(LogTag.rtc, 'error ${err.name}: $msg');
        events.onError(msg.isEmpty ? err.name : msg);
      },
    ));
    await engine.enableVideo();
    _engine = engine;
  }

  @override
  Future<void> startPreview() => engine.startPreview();

  @override
  Future<void> join({
    required String token,
    required String channelId,
    required int uid,
  }) =>
      engine.joinChannel(
        token: token,
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

  @override
  Future<void> setMicEnabled(bool enabled) =>
      engine.muteLocalAudioStream(!enabled);

  @override
  Future<void> setCamEnabled(bool enabled) =>
      engine.muteLocalVideoStream(!enabled);

  @override
  Future<void> flipCamera() => engine.switchCamera();

  @override
  Future<void> leave() async {
    await _engine?.stopPreview();
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    WtfLog.d(LogTag.rtc, 'left channel, engine released');
  }
}
