/// Supported Flutter architectures for project generation.
enum Architecture {
  bloc('Bloc (recommended)'),
  provider('Provider'),
  riverpod('Riverpod'),
  getx('GetX');

  const Architecture(this.label);

  /// Display label for interactive prompts.
  final String label;
}
