import 'package:flutter/material.dart';

/// The blue verified tick. Shown only when [AppUser.verified] is true
/// (a server-only flag — see firestore.rules).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) => Icon(
        Icons.verified,
        size: size,
        color: const Color(0xFF1D9BF0),
        semanticLabel: 'Verified',
      );
}
