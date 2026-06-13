import 'package:url_launcher/url_launcher.dart';

/// Open an external URL (e.g. a hosted checkout or signed document URL).
Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) throw 'Could not open the link.';
}
