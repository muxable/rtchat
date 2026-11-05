import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';

/// Preview text comes from ARB resources for the voice language, not the UI.
String ttsSampleMessage(String language) {
  final parts = language.replaceAll('_', '-').toLowerCase().split('-');
  final tag =
      parts.first == 'zh' &&
              parts.any(
                (part) => const ['hant', 'tw', 'hk', 'mo'].contains(part),
              )
          ? 'zh-Hant'
          : language;
  final locales = AppLocalizations.supportedLocales;
  final match = LanguageTag.bestMatch(
    tag,
    locales.map((locale) => locale.toLanguageTag()),
  );
  final locale = locales.firstWhere(
    (locale) => locale.toLanguageTag() == match,
    orElse: () => locales.first,
  );
  return lookupAppLocalizations(locale).sampleMessage;
}
