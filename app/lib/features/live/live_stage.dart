// Exposes [LiveStage] — the Agora-backed video surface on mobile (dart.library.io)
// and a placeholder on web. The host/viewer screens import this barrel only.
export 'live_stage_stub.dart' if (dart.library.io) 'live_stage_agora.dart';
