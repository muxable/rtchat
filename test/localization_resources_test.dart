import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts/language.dart';

void main() {
  final directory = Directory('lib/l10n');
  final template =
      jsonDecode(File('${directory.path}/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;
  final keys = template.keys.where((key) => !key.startsWith('@')).toSet();
  final placeholder = RegExp(r'\{(\w+)(?=[,}])');

  for (final file in directory.listSync().whereType<File>()) {
    if (!file.path.endsWith('.arb')) continue;
    test('${file.uri.pathSegments.last} has complete UI resources', () {
      final messages =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(messages.keys.where((key) => !key.startsWith('@')).toSet(), keys);
      for (final key in keys) {
        final value = messages[key] as String;
        expect(value.trim(), isNotEmpty, reason: key);
        expect(
          placeholder.allMatches(value).map((match) => match[1]).toSet(),
          placeholder
              .allMatches(template[key] as String)
              .map((match) => match[1])
              .toSet(),
          reason: '$key placeholders',
        );
        for (final tag in ['<b>', '</b>']) {
          expect(
            tag.allMatches(value).length,
            tag.allMatches(template[key] as String).length,
            reason: '$key $tag markup',
          );
        }
      }
    });
  }

  test('generated translations preserve native plural forms', () {
    final croatian = lookupAppLocalizations(const Locale('hr'));
    expect(croatian.newMessageCount(21), '21 nova poruka');
    expect(croatian.newMessageCount(22), '22 nove poruke');
    expect(croatian.newMessageCount(25), '25 novih poruka');
    final slovenian = lookupAppLocalizations(const Locale('sl'));
    expect(slovenian.newMessageCount(2), '2 novi sporočili');
    final latvian = lookupAppLocalizations(const Locale('lv'));
    expect(latvian.newMessageCount(10), '10 jaunu ziņojumu');
  });

  test('all speech languages support the app and Flutter UI delegates', () {
    for (final language in supportedLanguages) {
      final locale = Locale(language.split('-').first);
      expect(
        AppLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: language,
      );
    }
    for (final locale in AppLocalizations.supportedLocales) {
      expect(
        GlobalMaterialLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: locale.toLanguageTag(),
      );
      expect(
        GlobalCupertinoLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: locale.toLanguageTag(),
      );
      expect(
        GlobalWidgetsLocalizations.delegate.isSupported(locale),
        isTrue,
        reason: locale.toLanguageTag(),
      );
    }
  });
}
