import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeer_market/core/providers/locale_provider.dart';
import 'package:safeer_market/l10n/app_localizations.dart';

import 'test_helpers.dart';

final _arabic = RegExp(r'[\u0600-\u06FF]');

void main() {
  final languages = AppLanguage.values
      .map((language) => language.locale)
      .where((locale) => locale.languageCode != 'ar');

  for (final locale in languages) {
    for (final tab in [0, 1, 2, 3, 4]) {
      testWidgets(
          'tab $tab in ${locale.languageCode} is left-to-right with no Arabic',
          (tester) async {
        await pumpApp(
          tester,
          overrides: [localeProvider.overrideWith((ref) => locale)],
        );
        await skipSplash(tester);

        final l10n = lookupAppLocalizations(locale);
        final label =
            [l10n.home, l10n.search, l10n.cart, l10n.wallet, l10n.more][tab];
        await tester.tap(find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text(label),
        ));
        await tester.pumpAndSettle();

        final arabicTexts = [
          for (final text in tester.widgetList<RichText>(find.byType(RichText)))
            if (_arabic.hasMatch(text.text.toPlainText()))
              text.text.toPlainText(),
        ];
        expect(arabicTexts, isEmpty);
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.ltr,
        );
      });
    }
  }
}
