import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/call_cubit.dart';
import '../models/app_user.dart';
import '../models/room_meta.dart';
import '../services/call_service.dart';
import '../services/log_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';

/// Video call flow (spec §3D): pre-join device check → 2-tile grid call
/// with mute/video/flip/end → post-call sheet via [onEnded].
class CallScreen extends StatelessWidget {
  final AppUser me;
  final AppUser peer;
  final RoomMeta room;
  final Color roleColor;
  final LogService logService;
  final AgoraCallService callService;

  /// Invoked after the call ends and the SessionLog is written —
  /// each app shows its own post-call sheet (rating vs trainer notes).
  final void Function(BuildContext context, CallEnded state) onEnded;

  const CallScreen({
    super.key,
    required this.me,
    required this.peer,
    required this.room,
    required this.roleColor,
    required this.logService,
    required this.callService,
    required this.onEnded,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CallCubit(
        call: callService,
        logs: logService,
        me: me,
        room: room,
      )..startDeviceCheck(),
      child: BlocConsumer<CallCubit, CallState>(
        listener: (context, state) {
          if (state is CallEnded) onEnded(context, state);
        },
        builder: (context, state) => switch (state) {
          CallIdle() || CallJoining() => const Scaffold(
              backgroundColor: AppColors.grey900,
              body: Center(child: CircularProgressIndicator()),
            ),
          final CallPreviewing s =>
            _PreJoinView(state: s, service: callService),
          final CallInRoom s => _InCallView(
              state: s,
              service: callService,
              me: me,
              peer: peer,
              roleColor: roleColor),
          CallEnded() => const Scaffold(
              backgroundColor: AppColors.grey900,
              body: Center(child: CircularProgressIndicator()),
            ),
          CallFailed(:final message) => Scaffold(
              appBar: AppBar(title: const Text(AppStrings.joinCall)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.s24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: Gap.s16),
                      Text(message,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center),
                      const SizedBox(height: Gap.s16),
                      FilledButton(
                        onPressed: () =>
                            context.read<CallCubit>().startDeviceCheck(),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        },
      ),
    );
  }
}

/// Pre-join device check (spec §3D): camera preview + mic/cam toggles.
class _PreJoinView extends StatelessWidget {
  final CallPreviewing state;
  final AgoraCallService service;

  const _PreJoinView({required this.state, required this.service});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();
    return Scaffold(
      backgroundColor: AppColors.grey900,
      appBar: AppBar(
        backgroundColor: AppColors.grey900,
        foregroundColor: AppColors.white,
        title: const Text(AppStrings.deviceCheck),
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s16),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: state.camOn
                      ? AgoraVideoView(
                          controller: VideoViewController(
                            rtcEngine: service.engine,
                            canvas: const VideoCanvas(uid: 0),
                          ),
                        )
                      : Container(
                          color: AppColors.grey700,
                          child: const Center(
                            child: Icon(Icons.videocam_off,
                                size: 56, color: AppColors.grey300),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: Gap.s16),
              Text(AppStrings.joinPrompt,
                  style:
                      AppTextStyles.body.copyWith(color: AppColors.grey300)),
              const SizedBox(height: Gap.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundButton(
                    icon: state.micOn ? Icons.mic : Icons.mic_off,
                    active: state.micOn,
                    onTap: cubit.toggleMic,
                  ),
                  const SizedBox(width: Gap.s16),
                  _RoundButton(
                    icon: state.camOn ? Icons.videocam : Icons.videocam_off,
                    active: state.camOn,
                    onTap: cubit.toggleCam,
                  ),
                ],
              ),
              const SizedBox(height: Gap.s16),
              ElevatedButton(
                onPressed: cubit.join,
                child: const Text(AppStrings.joinCall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-call UI (spec §3D): 2-tile grid, name labels, controls, reconnect loader.
class _InCallView extends StatelessWidget {
  final CallInRoom state;
  final AgoraCallService service;
  final AppUser me;
  final AppUser peer;
  final Color roleColor;

  const _InCallView({
    required this.state,
    required this.service,
    required this.me,
    required this.peer,
    required this.roleColor,
  });

  Widget _tile({required Widget video, required String label}) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            video,
            Positioned(
              left: Gap.s8,
              bottom: Gap.s8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Gap.s8, vertical: Gap.s4),
                decoration: BoxDecoration(
                  color: AppColors.grey900.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.white)),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CallCubit>();
    return Scaffold(
      backgroundColor: AppColors.grey900,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.s8),
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _tile(
                      label: '${peer.name} ',
                      video: state.remoteUid != null
                          ? AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: service.engine,
                                canvas: VideoCanvas(uid: state.remoteUid),
                                connection: RtcConnection(
                                    channelId:
                                        cubit.room.channelId),
                              ),
                            )
                          : Container(
                              color: AppColors.grey700,
                              child: Center(
                                child: Text(
                                  state.peerLeft
                                      ? AppStrings.peerLeft
                                      : 'Waiting for ${peer.name}…',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.grey300),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: Gap.s8),
                  Expanded(
                    child: _tile(
                      label: '${me.name} (you)',
                      video: state.camOn
                          ? AgoraVideoView(
                              controller: VideoViewController(
                                rtcEngine: service.engine,
                                canvas: const VideoCanvas(uid: 0),
                              ),
                            )
                          : Container(
                              color: AppColors.grey700,
                              child: const Center(
                                child: Icon(Icons.videocam_off,
                                    size: 48, color: AppColors.grey300),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: Gap.s8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundButton(
                        icon: state.micOn ? Icons.mic : Icons.mic_off,
                        active: state.micOn,
                        onTap: cubit.toggleMic,
                      ),
                      const SizedBox(width: Gap.s16),
                      _RoundButton(
                        icon:
                            state.camOn ? Icons.videocam : Icons.videocam_off,
                        active: state.camOn,
                        onTap: cubit.toggleCam,
                      ),
                      const SizedBox(width: Gap.s16),
                      _RoundButton(
                        icon: Icons.cameraswitch,
                        active: true,
                        onTap: cubit.flipCamera,
                      ),
                      const SizedBox(width: Gap.s16),
                      _RoundButton(
                        icon: Icons.call_end,
                        active: true,
                        color: AppColors.error,
                        onTap: cubit.endCall,
                      ),
                    ],
                  ),
                ],
              ),
              if (state.reconnecting)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.grey900.withValues(alpha: 0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: Gap.s16),
                          Text(AppStrings.reconnecting,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 150),
      child: FloatingActionButton(
        heroTag: null,
        backgroundColor:
            color ?? (active ? AppColors.grey700 : AppColors.grey300),
        foregroundColor: active || color != null
            ? AppColors.white
            : AppColors.grey900,
        onPressed: onTap,
        child: Icon(icon),
      ),
    );
  }
}
