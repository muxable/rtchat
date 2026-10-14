import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';

void main() {
  group('parse', () {
    test('splits language, script and region, lowercased', () {
      expect(LanguageTag.parse('pt-BR'), const LanguageTag('pt', region: 'br'));
      expect(LanguageTag.parse('zh_Hant_TW'),
          const LanguageTag('zh', script: 'hant', region: 'tw'));
      expect(LanguageTag.parse('EN'), const LanguageTag('en'));
      expect(
          LanguageTag.parse('es-419'), const LanguageTag('es', region: '419'));
    });

    test('drops variants and extensions', () {
      expect(LanguageTag.parse('de-DE-1996'),
          const LanguageTag('de', region: 'de'));
      expect(LanguageTag.parse('en-US-u-ca-gregory'),
          const LanguageTag('en', region: 'us'));
    });

    test('implies the script of Chinese from the region', () {
      expect(LanguageTag.parse('zh-hk').script, 'hant');
      expect(LanguageTag.parse('zh-TW').script, 'hant');
      expect(LanguageTag.parse('zh-CN').script, 'hans');
      expect(LanguageTag.parse('zh').script, isNull);
    });

    test('replaces legacy codes', () {
      expect(LanguageTag.parse('iw').language, 'he');
      expect(LanguageTag.parse('in').language, 'id');
      expect(LanguageTag.parse('no').language, 'nb');
    });

    test('prints back as a normalized tag', () {
      expect(LanguageTag.parse('pt_BR').toString(), 'pt-br');
      expect(LanguageTag.parse('zh-Hant').toString(), 'zh-hant');
    });
  });

  group('matchScore', () {
    test('ranks exact, then the bare language, then regions', () {
      expect(LanguageTag.matchScore('pt-BR', 'pt-br'), 4);
      expect(LanguageTag.matchScore('pt-BR', 'pt'), 3);
      expect(LanguageTag.matchScore('en', 'en-US'), 2);
      expect(LanguageTag.matchScore('pt-BR', 'pt-PT'), 1);
      expect(LanguageTag.matchScore('pt', 'es'), 0);
    });

    test('scripts must agree when both are known', () {
      expect(LanguageTag.matchScore('zh-Hant', 'zh-Hans'), 0);
      expect(LanguageTag.matchScore('zh-TW', 'zh-CN'), 0);
      expect(LanguageTag.matchScore('zh-hk', 'zh-Hant'), 3);
      expect(LanguageTag.matchScore('zh-Hant', 'zh'), 3);
      expect(LanguageTag.matchScore('zh', 'zh-Hant'), 2);
    });

    test('an empty tag matches nothing', () {
      expect(LanguageTag.matchScore('', 'en'), 0);
    });
  });

  group('bestMatch', () {
    test('picks the best of the available tags', () {
      expect(LanguageTag.bestMatch('pt-BR', ['pt-PT', 'pt', 'pt-BR']), 'pt-BR');
      expect(LanguageTag.bestMatch('pt-BR', ['pt-PT', 'pt']), 'pt');
      expect(LanguageTag.bestMatch('en', ['en-US', 'en-GB']), 'en-US');
      expect(LanguageTag.bestMatch('es-MX', ['en', 'es-ES']), 'es-ES');
    });

    test('is null when nothing speaks the language', () {
      expect(LanguageTag.bestMatch('zh', ['en', 'ja']), isNull);
      expect(LanguageTag.bestMatch('zh-Hant', ['zh-Hans']), isNull);
      expect(LanguageTag.bestMatch('en', const []), isNull);
    });
  });
}
