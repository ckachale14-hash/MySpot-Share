import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repositories.dart';
import '../../core/widgets/live_video_surface.dart';
import 'live_chat_panel.dart';
import 'live_providers.dart';

class HostLiveScreen extends ConsumerStatefulWidget {
  const HostLiveScreen({super.key});

  @override
  ConsumerState<HostLiveScreen> createState() => _HostLiveScreenState();
}

class _HostLiveScreenState extends ConsumerState<HostLiveScreen> {
  final _title = TextEditingController();
  String? _streamId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final creds = await ref
          .read(liveRepositoryProvider)
          .createLive(title: _title.text.trim().isEmpty ? 'Live' : _title.text.trim());
      setState(() => _streamId = creds.streamId);
    } catch (e) {
      _toast('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    final id = _streamId;
    if (id != null) {
      try {
        await ref.read(liveRepositoryProvider).endLive(id);
      } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_streamId == null) return _setup();
    return _live(_streamId!);
  }

  Widget _setup() {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Live')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Host a discussion, product launch, or Q&A.'),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Stream title'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _start,
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.podcasts),
              label: const Text('Start streaming'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _live(String id) {
    final stream = ref.watch(liveStreamProvider(id)).value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: LiveVideoSurface(label: "You're live")),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
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
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _end,
                    child: const Text('End'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.45,
              child: LiveChatPanel(streamId: id),
            ),
          ],
        ),
      ),
    );
  }
}
