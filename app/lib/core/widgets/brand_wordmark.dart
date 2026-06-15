import 'package:flutter/material.dart';

/// The "MySpot Share" wordmark with the logo's blue→green split.
/// Uses the theme's primary (blue) and secondary (green) so it adapts to
/// light/dark automatically. Large bold text, so the green passes contrast.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.style, this.textAlign = TextAlign.center});

  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final base = (style ?? t.textTheme.displaySmall ?? const TextStyle())
        .copyWith(fontWeight: FontWeight.bold);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'MySpot', style: base.copyWith(color: t.colorScheme.primary)),
        TextSpan(text: ' Share', style: base.copyWith(color: t.colorScheme.secondary)),
      ]),
      textAlign: textAlign,
    );
  }
}
