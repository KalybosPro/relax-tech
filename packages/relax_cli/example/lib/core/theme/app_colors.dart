import 'package:flutter/material.dart';

/// Central color palette for the application.
///
/// Change [seed] to update the entire Material 3 color scheme.
/// Add custom overrides below as needed.
abstract final class AppColors {
  /// Primary seed color — the entire M3 palette derives from this.
  static const seed = Color(0xFF6750A4);

  // ── Custom overrides (optional) ──────────────────────────────
  // Add project-specific colors here, for example:
  // static const success = Color(0xFF4CAF50);
  // static const warning = Color(0xFFFFC107);
}
