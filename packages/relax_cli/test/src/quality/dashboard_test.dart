import 'dart:convert';
import 'dart:io';

import 'package:relax_cli/src/quality/dashboard/dashboard_server.dart';
import 'package:relax_cli/src/quality/models/quality_models.dart';
import 'package:test/test.dart';

QualityReport _report() => QualityReport(
  generatedAt: DateTime.utc(2026, 7, 5),
  projectScore: 84,
  filesAnalyzed: 12,
  stateManagement: {StateManagementKind.bloc},
  violations: [
    const ArchitectureViolation(
      type: 'controller_to_api',
      filePath: 'lib/a.dart',
      functionName: 'load',
      message: 'Controller → API',
      occurrences: 2,
      severity: Severity.error,
    ),
  ],
  issues: const [],
  testGaps: const [],
  graph: DependencyGraph(
    nodes: {
      'lib/a.dart::A': const GraphNode(
        id: 'lib/a.dart::A',
        layer: ArchLayer.controller,
        filePath: 'lib/a.dart',
        label: 'A',
      ),
    },
    edges: const [],
  ),
  heatmap: const {'auth': 42},
);

void main() {
  group('DashboardServer', () {
    late DashboardServer server;
    late HttpClient client;
    late Uri base;

    setUp(() async {
      server = DashboardServer(report: _report());
      base = await server.start(preferredPort: 0); // ephemeral
      client = HttpClient();
    });
    tearDown(() async {
      client.close(force: true);
      await server.stop();
    });

    Future<(int, String)> get(String path) async {
      final req = await client.getUrl(base.replace(path: path));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      return (res.statusCode, body);
    }

    test('binds to loopback only', () {
      expect(base.host, '127.0.0.1');
    });

    test('serves the SPA at /', () async {
      final (status, body) = await get('/');
      expect(status, 200);
      expect(body, contains('<title>relax quality</title>'));
      expect(body, contains('/api/report'));
    });

    test('serves the full report at /api/report', () async {
      final (status, body) = await get('/api/report');
      expect(status, 200);
      final json = jsonDecode(body) as Map<String, Object?>;
      expect(json['projectScore'], 84);
      expect(json['schemaVersion'], '1.0');
      expect((json['violations'] as List), hasLength(1));
    });

    test('serves granular endpoints', () async {
      expect((await get('/api/score')).$1, 200);
      expect((await get('/api/violations')).$1, 200);
      final (gStatus, gBody) = await get('/api/graph');
      expect(gStatus, 200);
      expect((jsonDecode(gBody) as Map)['nodes'], hasLength(1));
    });

    test('404s unknown paths', () async {
      expect((await get('/nope')).$1, 404);
    });
  });
}
