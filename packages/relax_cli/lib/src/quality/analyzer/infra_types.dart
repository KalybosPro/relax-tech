/// Shared classification of "infrastructure" dependency types — repositories,
/// data sources, services, clients, gateways — used by the mock generator and
/// the UseCase generator to decide what to inject/mock.
abstract final class InfraTypes {
  static const List<String> fragments = [
    'Repository',
    'DataSource',
    'Datasource',
    'Service',
    'ApiClient',
    'ApiService',
    'Client',
    'UseCase',
    'Usecase',
    'Gateway',
    'Provider',
  ];

  /// Whether [typeName] looks like an infrastructure dependency.
  static bool isInfra(String typeName) {
    final base = baseType(typeName);
    if (base.isEmpty) return false;
    return fragments.any(base.contains);
  }

  /// Strips generics and nullability: `Repository<T>?` → `Repository`.
  static String baseType(String type) {
    var t = type.trim();
    final open = t.indexOf('<');
    if (open != -1) t = t.substring(0, open);
    return t.replaceAll('?', '').trim();
  }
}
