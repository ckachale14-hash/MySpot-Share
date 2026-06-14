import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/widgets/live_video_surface.dart';

/// Mobile live video via Agora. Hosts publish their camera; viewers subscribe to
/// the host. Credentials (appId/channel/token/uid) are minted server-side.
class LiveStage extends StatefulWidget {
  const LiveStage({
    super.key,
    required this.appId,
    required this.channel,
    required this.token,
    required this.uid,
    required this.host,
  });

  final String appId;
  final String channel;
  final String token;
  final int uid;
  final bool host;

  @override
  State<LiveStage> createState() => _LiveStageState();
}

class _LiveStageState extends State<LiveStage> {
  RtcEngine? _engine;
  int? _remoteUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.appId.isEmpty) {
      setState(() => _error = 'Live video is not configured.');
      return;
    }
    try {
      if (widget.host) {
        await [Permission.camera, Permission.microphone].request();
      }
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: widget.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      engine.registerEventHandler(RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted && _remoteUid == remoteUid) {
            setState(() => _remoteUid = null);
          }
        },
      ));

      if (widget.host) {
        await engine.enableVideo();
        await engine.startPreview();
      }

      await engine.joinChannel(
        token: widget.token,
        channelId: widget.channel,
        uid: widget.uid,
        options: ChannelMediaOptions(
          clientRoleType: widget.host
              ? ClientRoleType.clientRoleBroadcaster
              : ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      if (mounted) setState(() => _engine = engine);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    final engine = _engine;
    if (engine != null) {
      engine.leaveChannel();
      engine.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return LiveVideoSurface(label: _error!);
    final engine = _engine;
    if (engine == null) return const LiveVideoSurface(label: 'Connecting…');

    if (widget.host) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    final remote = _remoteUid;
    if (remote == null) {
      return const LiveVideoSurface(label: 'Waiting for the host…');
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: remote),
        connection: RtcConnection(channelId: widget.channel),
      ),
    );
  }
}
