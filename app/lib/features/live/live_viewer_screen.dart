import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/live_video_surface.dart';
import '../../domain/entities/live_stream.dart';
import 'live_chat_panel.dart';
import 'live_providers.dart';
import 'live_stage.dart';

class LiveViewerScreen extends ConsumerStatefulWidget {
  const LiveViewerScreen({super.key, required this.streamId});
  final String streamId;

  @override
  ConsumerState<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends ConsumerState<LiveViewerScreen> {
  LiveCredentials? _creds;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(liveRepositoryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final creds = await repo.joinLive(widget.streamId);
        if (mounted) setState(() => _creds = creds);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    final repo = ref.read(liveRepositoryProvider);
    () async {
      try {
        await repo.leaveLive(widget.streamId);
      } catch (_) {}
    }();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(liveStreamProvider(widget.streamId)).value;
    final ended = stream != null && stream.status != 'live';
    final creds = _creds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ended
                  ? const LiveVideoSurface(label: 'This stream has ended')
                  : (creds == null
                      ? const LiveVideoSurface(label: 'Joining…')
                      : LiveStage(
                          appId: creds.appId,
                          channel: creds.channel,
                          token: creds.token,
                          uid: creds.uid,
                          host: false,
                        )),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(
                      (stream?.host.displayName.isNotEmpty ?? false)
                          ? stream!.host.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(stream?.host.displayName ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.visibility, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('${stream?.viewerCount ?? 0}',
                          style: const TextStyle(color: Colors.white)),
                    ]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            if (!ended)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: LiveChatPanel(streamId: widget.streamId),
              ),
          ],
        ),
      ),
    );
  }
}
