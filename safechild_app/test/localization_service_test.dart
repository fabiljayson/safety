import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:safechild_app/services/localization_service.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('fr');
  });
  group('translate', () {
    test('returns the value for the active locale', () {
      expect(const AppTranslations(Locale('en')).translate('login'), 'Login');
      expect(
        const AppTranslations(Locale('fr')).translate('login'),
        'Connexion',
      );
    });

    test('falls back to the key when a translation is missing', () {
      expect(
        const AppTranslations(Locale('en')).translate('not_a_real_key'),
        'not_a_real_key',
      );
    });
  });

  group('ageLabel', () {
    test('uses the French singular for one year old', () {
      expect(const AppTranslations(Locale('fr')).ageLabel(1), '1 an');
    });

    test('uses the French plural for more than one', () {
      expect(const AppTranslations(Locale('fr')).ageLabel(5), '5 ans');
    });

    test('uses English wording, which has no singular unit noun', () {
      expect(const AppTranslations(Locale('en')).ageLabel(1), '1 year old');
      expect(const AppTranslations(Locale('en')).ageLabel(5), '5 years old');
    });
  });

  group('missingSince', () {
    final date = DateTime(2026, 9, 14);

    test('localises both the label and the date order', () {
      expect(
        const AppTranslations(Locale('fr')).missingSince(date),
        'Recherché depuis le 14 sept. 2026',
      );
      expect(
        const AppTranslations(Locale('en')).missingSince(date),
        'Missing since Sep 14, 2026',
      );
    });
  });

  group('locale parity', () {
    test('English and French define exactly the same keys', () {
      final en = AppTranslations.keysFor('en');
      final fr = AppTranslations.keysFor('fr');

      expect(en, isNotEmpty);
      expect(en.difference(fr), isEmpty, reason: 'keys missing from French');
      expect(fr.difference(en), isEmpty, reason: 'keys missing from English');
    });

    test('every supported language has a non-empty map', () {
      for (final code in const ['en', 'fr']) {
        expect(
          AppTranslations.keysFor(code),
          isNotEmpty,
          reason: 'no translations for $code',
        );
      }
    });

    test('English is the default language', () {
      expect(defaultLanguageCode, 'en');
    });
  });
}
