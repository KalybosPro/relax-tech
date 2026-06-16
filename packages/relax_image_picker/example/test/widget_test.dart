// Smoke test for the relax_image_picker example app.

import 'package:flutter_test/flutter_test.dart';

import 'package:relax_image_picker_example/main.dart';

void main() {
  testWidgets('Example app renders the picker entry buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Défaut'), findsOneWidget);
    expect(find.text('Thème + builders'), findsOneWidget);
  });
}
