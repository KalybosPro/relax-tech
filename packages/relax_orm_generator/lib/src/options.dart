import 'package:build/build.dart';

/// Build-time configuration of the `relax_orm` builder.
///
/// Set through `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       relax_orm_generator:relax_orm:
///         options:
///           seed: true
///           seed_count: 25
/// ```
///
/// …or, more commonly, from the command line — which is what
/// `dart run relax_orm --seed` does under the hood:
///
/// ```bash
/// dart run build_runner build \
///   --define="relax_orm_generator:relax_orm=seed=true"
/// ```
class RelaxOrmOptions {
  const RelaxOrmOptions({this.seed = false, this.seedCount = 10});

  /// Generate a `TableSeeder` for every `@RelaxTable` model.
  ///
  /// Models carrying `@RelaxSeed()` get a seeder regardless of this flag;
  /// `@RelaxSeed(enabled: false)` opts a model out even when it is on.
  final bool seed;

  /// Default row count for generated seeders that don't specify one via
  /// `@RelaxSeed(count: …)`.
  final int seedCount;

  /// Reads the options from [BuilderOptions], falling back to the defaults.
  factory RelaxOrmOptions.fromBuilderOptions(BuilderOptions options) {
    final config = options.config;
    return RelaxOrmOptions(
      seed: _readBool(config['seed']) ?? false,
      seedCount: _readInt(config['seed_count']) ?? 10,
    );
  }

  /// `--define` always arrives as a string, `build.yaml` as a real bool.
  static bool? _readBool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null && parsed >= 0) return parsed;
    }
    return null;
  }
}
