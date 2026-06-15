import 'package:flutter/material.dart';

/// MySpot Share brand colors — see docs/brand/BRAND.md.
/// Fill tokens (green/coral) are for buttons, badges, icons and large text;
/// for small text on white use the *Text variants, which pass WCAG AA.
abstract final class Brand {
  // Core palette (sampled from the brand artwork)
  static const blue = Color(0xFF0052B4); // primary
  static const green = Color(0xFF329B32); // secondary / success (fill)
  static const coral = Color(0xFFFA4B4B); // accent (fill)
  static const ink = Color(0xFF121F34); // text / dark surface
  static const cloud = Color(0xFFF3F6F9); // light background

  // Accessible text variants on white (small text / button labels)
  static const greenText = Color(0xFF1E7A2E);
  static const coralText = Color(0xFFC92F2F);

  // Distinct error red — kept separate from coral so "delete" ≠ "accent"
  static const error = Color(0xFFC62828);

  // Lighter brand tints for contrast on dark surfaces
  static const blueOnDark = Color(0xFF3375C3); // Blue-400
  static const greenOnDark = Color(0xFF84C384); // Green-300
  static const coralOnDark = Color(0xFFFC9393); // Coral-300
  static const errorOnDark = Color(0xFFEF6C6C);

  // Dark-mode surfaces
  static const darkBackground = Color(0xFF0E1726);
  static const darkSurface = Color(0xFF121F34);
  static const onDark = Color(0xFFE6ECF5);

  // Logo gradient endpoints
  static const azure = Color(0xFF0091FF);
  static const lime = Color(0xFFA3FF2A);

  /// Primary brand gradient (blue → green), for hero/splash/premium surfaces.
  static const brandGradient = LinearGradient(colors: [blue, green]);
}
