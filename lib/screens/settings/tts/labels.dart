import 'package:flutter/widgets.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// [bytes] in megabytes, e.g. `401 MB`.
String formatBytes(int bytes) => '${(bytes / 1e6).round()} MB';

/// The name of [language], a BCP-47 tag such as `pt` or `pt-BR`, in the
/// app's language, e.g. `Portuguese (Brazil)`; the tag itself if there is
/// no name for it.
String languageName(BuildContext context, String language) {
  final tag = LanguageTag.parse(language);
  final names = LocaleNames.of(context);
  final region = tag.region;
  final code =
      region == null ? tag.language : '${tag.language}_${region.toUpperCase()}';
  return names?.nameOf(code) ?? names?.nameOf(tag.language) ?? language;
}

/// [languages] sorted by their names in the app's language.
List<String> sortLanguages(BuildContext context, Iterable<String> languages) {
  final names = {for (final l in languages) l: languageName(context, l)};
  return names.keys.toList()
    ..sort(
        (a, b) => names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase()));
}
