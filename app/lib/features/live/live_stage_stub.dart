import 'package:flutter/material.dart';

import '../../core/widgets/live_video_surface.dart';

/// Web/desktop fallback: Agora's mobile video engine isn't used here, so we show
/// the placeholder. The real engine lives in live_stage_agora.dart (mobile).
class LiveStage extends StatelessWidget {
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
  Widget build(BuildContext context) => LiveVideoSurface(
      label: host ? "You're live (preview)" : 'Live (preview)');
}
