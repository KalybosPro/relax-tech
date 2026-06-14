import 'package:flutter_test/flutter_test.dart';

import 'package:example/app/app.dart';
import 'package:example/i18n/slang/translations.g.dart';

void main() {
  testWidgets('App renders HomePage', (tester) async {
    LocaleSettings.setLocale(AppLocale.en);
    await tester.pumpWidget(TranslationProvider(child: const App()));
    expect(find.text(t.appName), findsOneWidget);
  });
}
