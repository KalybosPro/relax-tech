// Smoke test for the example app: it checks that the generated `env` package
// resolves values through AppFlavor and that the app builds with them.

import 'package:env/env.dart';
import 'package:env_builder_cli_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds and shows its title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Env Builder CLI'), findsOneWidget);
  });

  test('AppFlavor resolves generated env values', () {
    final flavor = AppFlavor.development();

    expect(flavor.getEnv(Env.baseUrl), isNotEmpty);
  });
}
