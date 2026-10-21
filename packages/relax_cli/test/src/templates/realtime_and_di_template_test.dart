import 'dart:convert';

import 'package:mason/mason.dart';
import 'package:relax_cli/src/templates/bloc_app_template.dart';
import 'package:relax_cli/src/templates/feature_template.dart';
import 'package:relax_cli/src/templates/getx_app_template.dart';
import 'package:relax_cli/src/templates/provider_app_template.dart';
import 'package:relax_cli/src/templates/riverpod_app_template.dart';
import 'package:relax_cli/src/templates/shared_template.dart';
import 'package:test/test.dart';

String _content(List<TemplateFile> files, String suffix) =>
    utf8.decode(files.firstWhere((f) => f.path.endsWith(suffix)).content);

void main() {
  final templates = <String, List<TemplateFile>>{
    'bloc': BlocAppTemplate.files,
    'provider': ProviderAppTemplate.files,
    'riverpod': RiverpodAppTemplate.files,
    'getx': GetxAppTemplate.files,
  };

  group('--socket', () {
    for (final entry in templates.entries) {
      test('${entry.key} pubspec picks the socket package', () {
        final pubspec = _content(entry.value, 'pubspec.yaml');
        final io = pubspec.render({'project_name': 'app', 'socket_io': true});
        final ws = pubspec.render({'project_name': 'app', 'socket_io': false});

        expect(io, contains('  socket_io_client: ^3.1.6\n'));
        expect(io, isNot(contains('web_socket_channel')));
        expect(ws, contains('  web_socket_channel: ^3.0.3\n'));
        expect(ws, isNot(contains('socket_io_client')));
        expect(ws, isNot(contains('{{')));
        for (final rendered in [io, ws]) {
          expect(
            rendered,
            isNot(contains('\n\n\n')),
            reason: 'stray blank lines',
          );
        }
      });
    }

    test('socket client and service render the chosen transport', () {
      final client = SharedTemplate.socketClient;
      final service = SharedTemplate.socketService;

      final ioClient = client.render({'socket_io': true});
      expect(ioClient, startsWith('import '));
      expect(ioClient, contains('package:socket_io_client'));
      expect(ioClient, isNot(contains('web_socket_channel')));
      expect(
        service.render({'socket_io': true}),
        contains('Stream<dynamic> on('),
      );

      final wsClient = client.render({'socket_io': false});
      expect(wsClient, contains('package:web_socket_channel'));
      expect(wsClient, isNot(contains('socket_io_client')));
      expect(service.render({'socket_io': false}), contains('get messages'));
    });
  });

  group('Riverpod DI', () {
    final files = RiverpodAppTemplate.files;
    final paths = files.map((f) => f.path).toList();

    test('does not depend on get_it', () {
      expect(_content(files, 'pubspec.yaml'), isNot(contains('get_it')));
      expect(paths.any((p) => p.endsWith('/injection.dart')), isFalse);
      for (final file in files) {
        expect(
          utf8.decode(file.content),
          isNot(contains('package:get_it')),
          reason: '${file.path} imports get_it',
        );
      }
    });

    test('declares core providers and overrides env in bootstrap', () {
      expect(
        _content(files, 'dependency_injection/providers.dart'),
        allOf(contains('final apiClientProvider'), contains('envProvider')),
      );
      expect(
        _content(files, 'lib/bootstrap.dart'),
        contains('envProvider.overrideWithValue(env)'),
      );
    });

    test('generated feature notifier resolves ApiClient from a provider', () {
      final notifier = _content(FeatureTemplate.riverpod, '_notifier.dart');
      expect(notifier, contains('ref.watch(apiClientProvider)'));
      expect(notifier, isNot(contains('getIt')));
    });

    test('other architectures keep the get_it service locator', () {
      for (final arch in ['bloc', 'provider', 'getx']) {
        expect(_content(templates[arch]!, 'pubspec.yaml'), contains('get_it'));
        expect(
          templates[arch]!.any((f) => f.path.endsWith('/injection.dart')),
          isTrue,
        );
      }
    });
  });
}
