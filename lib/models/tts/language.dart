import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

const supportedLanguages = [
  'af', //    Afrikaans
  'ar', //    Arabic
  'bn', //    Bengali
  'bg', //    Bulgarian
  'ca', //    Catalan
  'zh', //    Chinese
  'zh-hk', // Chinese (Hong Kong)
  'cs', //    Czech
  'da', //    Danish
  'nl', //    Dutch
  'en', //    English
  'fi', //    Finnish
  'fr', //    French
  'de', //    German
  'el', //    Greek
  'gu', //    Gujarati
  'hi', //    Hindi
  'hu', //    Hungarian
  'is', //    Icelandic
  'id', //    Indonesian
  'it', //    Italian
  'ja', //    Japanese
  'kn', //    Kannada
  'ko', //    Korean
  'lv', //    Latvian
  'ms', //    Malay
  'ml', //    Malayalam
  'nb', //    Norwegian Bokmål
  'pl', //    Polish
  'pt', //    Portuguese
  'pa', //    Punjabi
  'ro', //    Romanian
  'ru', //    Russian
  'sr', //    Serbian
  'sk', //    Slovak
  'es', //    Spanish
  'sv', //    Swedish
  'tl', //    Tagalog
  'ta', //    Tamil
  'te', //    Telugu
  'th', //    Thai
  'tr', //    Turkish
  'uk', //    Ukrainian
  'vi', //    Vietnamese
];

class Language {
  final String languageCode;

  Language([this.languageCode = 'en']);

  String displayName(BuildContext context) {
    // LocaleNames requires country codes to be uppercase
    if (languageCode.contains('-')) {
      final index = languageCode.indexOf('-');
      final countryCode = languageCode.substring(index).toUpperCase();
      final code = languageCode
          .replaceRange(index, null, countryCode)
          .replaceAll('-', '_');
      return LocaleNames.of(context)!.nameOf(code) ?? '';
    }
    return LocaleNames.of(context)!.nameOf(languageCode) ?? '';
  }
}
