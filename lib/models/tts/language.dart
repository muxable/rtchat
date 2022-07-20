import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

const supportedLanguages = [
  'af-ZA', // Afrikaans
  'ar', //    Arabic
  'bn-IN', // Bengali
  'bg-BG', // Bulgarian
  'ca-ES', // Catalan
  'zh-CN', // Chinese (China)
  'zh-HK', // Chinese (Hong Kong)
  'cs-CZ', // Czech
  'da-DK', // Danish
  'nl-BE', // Dutch (Belgium)
  'nl-NL', // Dutch (Netherlands)
  'en-AU', // English (Australia)
  'en-IN', // English (India)
  'en-NZ', // English (New Zealand)
  'en-ZA', // English (South Africa)
  'en-GB', // English (United Kingdom)
  'en-US', // English (United States)
  'fi-FI', // Finnish
  'fr-CA', // French (Canada)
  'fr-FR', // French (France)
  'de-DE', // German
  'el-GR', // Greek
  'gu-IN', // Gujarati
  'hi-IN', // Hindi
  'hu-HU', // Hungarian
  'is-IS', // Icelandic
  'id-ID', // Indonesian
  'it-IT', // Italian
  'ja-JP', // Japanese
  'kn-IN', // Kannada
  'ko-KR', // Korean
  'lv-LV', // Latvian
  'ms-MY', // Malay
  'ml-IN', // Malayalam
  'nb-NO', // Norwegian Bokmål
  'pl-PL', // Polish
  'pt-BR', // Portuguese (Brazil)
  'pt-PT', // Portuguese (Portugal)
  'pa-IN', // Punjabi
  'ro-RO', // Romanian
  'ru-RU', // Russian
  'sr-RS', // Serbian
  'sk-SK', // Slovak
  'es-MX', // Spanish (Mexico)
  'es-ES', // Spanish (Spain)
  'es-US', // Spanish (United States)
  'sv-SE', // Swedish
  'tl-PH', // Tagalog
  'ta-IN', // Tamil
  'te-IN', // Telugu
  'th-TH', // Thai
  'tr-TR', // Turkish
  'uk-UA', // Ukrainian
  'vi-VN', // Vietnamese
  'cy-GB', // Welsh
];

class Language {
  final String languageCode;

  Language([String? languageCode])
      : languageCode = languageCode ??
            (supportedLanguages
                    .contains(Platform.localeName.replaceAll('_', '-'))
                ? Platform.localeName.replaceAll('_', '-')
                : 'en-US');

  String displayName(BuildContext context) {
    final code = languageCode.replaceAll('-', '_');
    return LocaleNames.of(context)!.nameOf(code) ?? '';
  }
}
