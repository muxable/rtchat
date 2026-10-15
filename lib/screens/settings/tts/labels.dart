import 'package:flutter/widgets.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:intl/intl.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';

/// [bytes] as megabytes or gigabytes, e.g. `401 MB` or `1.2 GB`.
String formatBytes(BuildContext context, int bytes) {
  String format(String pattern, num value) {
    try {
      return NumberFormat(pattern, Localizations.localeOf(context).toString())
          .format(value);
    } on Object {
      return NumberFormat(pattern, 'en').format(value);
    }
  }

  if (bytes >= 1000000000) return '${format('0.#', bytes / 1e9)} GB';
  final megabytes = bytes / 1e6;
  return '${format(megabytes >= 10 ? '0' : '0.#', megabytes)} MB';
}

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

/// [languages] sorted by their names in the app's language, with
/// [first] (if it's one of them) at the start.
List<String> sortLanguages(BuildContext context, Iterable<String> languages,
    {String? first}) {
  final names = {for (final l in languages) l: languageName(context, l)};
  return names.keys.toList()
    ..sort((a, b) {
      if (a == first) return -1;
      if (b == first) return 1;
      return names[a]!.toLowerCase().compareTo(names[b]!.toLowerCase());
    });
}

/// The license's name to show, e.g. `OpenRAIL-M` for
/// `LicenseRef-OpenRAIL-M`.
String licenseName(VoicePackLicense license) =>
    license.name.replaceFirst(RegExp('^LicenseRef-'), '');

/// Whether [license] is a Responsible AI License (OpenRAIL), whose use
/// restrictions have to be passed on to users.
bool isOpenRail(VoicePackLicense? license) =>
    license != null && license.name.toLowerCase().contains('openrail');

/// Why installing a pack failed, for people.
String installErrorReason(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  return switch (error) {
    VoicePackDownloadException() => l10n.voicePackErrorDownload,
    VoicePackChecksumException() => l10n.voicePackErrorDamaged,
    _ => l10n.voicePackErrorUnknown,
  };
}
