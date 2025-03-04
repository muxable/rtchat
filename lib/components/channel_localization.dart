import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChannelLocalization extends ChangeNotifier {
  Locale? _channelLocale;

  void setChannelLanguage(String? languageCode) {
    if (languageCode != null) {
      _channelLocale = Locale(normalizeLanguageCode(languageCode));
    } else {
      _channelLocale = null;
    }
    notifyListeners();
  }

  static Locale? getLocale(BuildContext context) {
    return Provider.of<ChannelLocalization>(context, listen: false)
        ._channelLocale;
  }

  static String normalizeLanguageCode(String? twitchLang) {
    final mappings = {
      'en': 'en',
      'es': 'es',
      'fr': 'fr',
      'de': 'de',
      'it': 'it',
      'ar': 'ar',
      'bn': 'bn',
      'ja': 'ja',
      'ko': 'ko',
      'nl': 'nl',
      'pl': 'pl',
      'pt': 'pt',
      'ru': 'ru',
      'sv': 'sv',
      'uk': 'uk',
      'zh': 'zh',
      'zh-Hant': 'zh',
    };
    return mappings[twitchLang] ?? 'en';
  }
}
