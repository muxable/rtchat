import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts.dart';

import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';

void main() {
  late TtsModel tts;

  Future<void> open(WidgetTester tester,
      {String language = 'en',
      bool neural = false,
      bool isSupported = true}) async {
    final packs =
        VoicePacksModel(FakeVoicePackRepository(), isSupported: isSupported);
    tts = TtsModel.fromJson(const {},
        engine: FakeTtsEngine(), reportError: (e, st) => throw e)
      ..language = Language(language);
    if (neural) {
      tts.neuralEngine =
          FakeTtsEngine(availableVoices: packVoices(['en', 'fr']));
    }
    addTearDown(() {
      packs.dispose();
      tts.dispose();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tts),
        ChangeNotifierProvider.value(value: packs),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          LocaleNamesLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TextToSpeechScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('reads with the system voice without a voice pack',
      (tester) async {
    await open(tester);
    expect(find.text('System voice'), findsOneWidget);
    expect(find.text('Voices'), findsNothing);

    await tester.tap(find.text('Voice packs'));
    await tester.pumpAndSettle();
    expect(find.text('Supertonic 3'), findsOneWidget);
  });

  testWidgets('reads with the neural voice once a pack is installed',
      (tester) async {
    await open(tester, neural: true);
    expect(find.text('Neural voice (on-device)'), findsOneWidget);
    expect(find.textContaining("isn't supported"), findsNothing);

    await tester.tap(find.text('Voices'));
    await tester.pumpAndSettle();
    expect(find.text('Per-viewer voice'), findsOneWidget);
  });

  testWidgets('says when the stream language is not supported', (tester) async {
    await open(tester, language: 'th', neural: true);
    expect(
        find.text(
            "Thai isn't supported by your voice packs; the system voice will be used"),
        findsOneWidget);
  });

  testWidgets('tells once that neural voices cannot run', (tester) async {
    await open(tester, neural: true);
    tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
    await tester.pumpAndSettle();
    expect(find.text('System voice'), findsOneWidget);
    expect(find.textContaining("doesn't have enough memory"), findsOneWidget);
    expect(find.text('Voices'), findsNothing);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(tts.isNeuralFallbackNoticePending, isFalse);
    expect(find.textContaining("doesn't have enough memory"), findsNothing);
    expect(find.text('System voice'), findsOneWidget);
  });

  testWidgets('hides the voice settings where neural voices are unsupported',
      (tester) async {
    await open(tester, isSupported: false);
    expect(find.text('System voice'), findsNothing);
    expect(find.text('Voice packs'), findsNothing);
  });
}
