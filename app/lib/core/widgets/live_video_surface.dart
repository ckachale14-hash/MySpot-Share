import 'package:flutter/material.dart';

/// Placeholder for the live video surface. The control plane (server-minted
/// tokens, channel, viewer counts, chat) is fully wired; rendering the actual
/// video stream is done with `agora_rtc_engine` on device — drop the engine view
/// in here, using the LiveCredentials (appId/channel/token/uid) from the repo.
class LiveVideoSurface extends StatelessWidget {
  const LiveVideoSurface({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF14142B), Color(0xFF3D5AFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, color: Colors.white70, size: 48),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            const Text('Video renders via agora_rtc_engine on device',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
