import 'package:flutter/widgets.dart';

/// Locales offered by the app UI. Other ARB locales provide TTS samples/preludes
/// only and must not change the app's UI locale resolution.
const supportedUiLocales = <Locale>[
  Locale('en'),
  Locale('ar'),
  Locale('bn'),
  Locale('de'),
  Locale('es'),
  Locale('fr'),
  Locale('it'),
  Locale('ja'),
  Locale('ko'),
  Locale('nl'),
  Locale('pl'),
  Locale('pt'),
  Locale('ru'),
  Locale('sv'),
  Locale('uk'),
  Locale('zh'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];
