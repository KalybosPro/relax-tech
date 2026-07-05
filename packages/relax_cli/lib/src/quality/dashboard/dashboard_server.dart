import 'dart:convert';
import 'dart:io';

import '../models/quality_models.dart';
import 'dashboard_html.dart';

/// A lightweight, embedded HTTP server that serves the quality dashboard.
///
/// It binds to loopback only (no network exposure by default), serves a
/// self-contained single-page app at `/`, and exposes the report as JSON under
/// `/api/*`. Everything is pre-computed: the SPA never recalculates a score,
/// it only renders the report it is given.
class DashboardServer {
  DashboardServer({required this.report, this.history = const []});

  final QualityReport report;

  /// Historical runs for the trend chart (empty until the store lands).
  final List<Map<String, Object?>> history;

  HttpServer? _server;

  int get port => _server?.port ?? 0;
  Uri get url => Uri.parse('http://127.0.0.1:$port');

  /// Starts listening on [preferredPort] (loopback). Falls back to an
  /// ephemeral port if the preferred one is taken.
  Future<Uri> start({int preferredPort = 8080}) async {
    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        preferredPort,
      );
    } on SocketException {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    _server!.listen(_handle);
    return url;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  void _handle(HttpRequest request) {
    final path = request.uri.path;
    try {
      switch (path) {
        case '/' || '/index.html':
          _html(request, dashboardHtml);
        case '/api/report':
          _json(request, report.toJson());
        case '/api/score':
          _json(request, {
            'projectScore': report.projectScore,
            'previousScore': report.previousScore,
            'filesAnalyzed': report.filesAnalyzed,
            'stateManagement': report.stateManagement.map((s) => s.id).toList(),
          });
        case '/api/coverage':
          _json(request, report.coverage?.toJson() ?? {});
        case '/api/violations':
          _json(request, {
            'violations': report.violations.map((v) => v.toJson()).toList(),
            'issues': report.issues.map((i) => i.toJson()).toList(),
          });
        case '/api/graph':
          _json(request, report.graph.toJson());
        case '/api/history':
          _json(request, {'history': history});
        default:
          _notFound(request);
      }
    } on Object catch (e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..write('Internal error: $e')
        ..close();
    }
  }

  void _html(HttpRequest request, String body) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..headers.set('Cache-Control', 'no-store')
      ..write(body)
      ..close();
  }

  void _json(HttpRequest request, Object? body) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set('Cache-Control', 'no-store')
      ..write(jsonEncode(body))
      ..close();
  }

  void _notFound(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..write('Not found')
      ..close();
  }
}

/// Best-effort attempt to open [url] in the default browser. Never throws.
Future<void> openInBrowser(Uri url) async {
  try {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url.toString()]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url.toString()]);
    } else {
      await Process.run('xdg-open', [url.toString()]);
    }
  } on Object {
    // Ignore — the URL is printed to the console as a fallback.
  }
}
