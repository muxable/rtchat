import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';

import '../../fakes/fake_voice_pack_repository.dart';
import 'tts_harness.dart';

const _unsupportedThai =
    "Thai isn't supported by your voice packs; the system voice will be used";

void main() {
  Future<TtsHarness> open(WidgetTester tester,
      {String streamLanguage = 'en',
      TtsMode mode = TtsMode.disabled,
      List<String>? installed}) async {
    final harness = TtsHarness(streamLanguage: streamLanguage, mode: mode);
    if (installed != null) {
      harness.repository.add(testPack(languages: installed));
      harness.addEngine(installed);
    }
    await tester.pumpWidget(harness.app(const TextToSpeechScreen()));
    await tester.pumpAndSettle();
    return harness;
  }

  group('engine', () {
    testWidgets('is the system voice without a voice pack', (tester) async {
      await open(tester);
      expect(find.text('Reads chat with'), findsOneWidget);
      expect(find.text('System voice'), findsOneWidget);
      expect(
          find.text('Download natural-sounding voices that run on your device'),
          findsOneWidget);
      // nothing to pick yet.
      expect(find.text('Voices'), findsNothing);
      expect(find.byType(PerViewerVoiceSwitch), findsNothing);
      // the settings that were there before stay.
      for (final setting in [
        'Play sample message',
        'Mute text to speech for bots',
        'Subscribers only',
      ]) {
        await tester.scrollUntilVisible(find.text(setting), 100);
        expect(find.text(setting), findsOneWidget, reason: setting);
      }
    });

    testWidgets('is neural with a voice pack', (tester) async {
      await open(tester, installed: ['en']);
      expect(find.text('Neural voice (on-device)'), findsOneWidget);
      expect(find.text('1 installed · 402 MB'), findsOneWidget);
      expect(find.text('Voices'), findsOneWidget);
      expect(find.byType(PerViewerVoiceSwitch), findsOneWidget);
    });

    testWidgets('leads to the voice packs and the voices', (tester) async {
      await open(tester, installed: ['en']);
      await tester.tap(find.text('Voice packs'));
      await tester.pumpAndSettle();
      expect(find.byType(VoicePacksScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voices'));
      await tester.pumpAndSettle();
      expect(find.byType(VoiceLanguagesScreen), findsOneWidget);
    });

    testWidgets('follows packs being installed and deleted', (tester) async {
      final harness = await open(tester);
      expect(find.text('System voice'), findsOneWidget);
      harness.repository.add(testPack());
      await tester.pumpAndSettle();
      expect(find.text('Neural voice (on-device)'), findsOneWidget);
      await harness.repository.delete('supertonic-3');
      await tester.pumpAndSettle();
      expect(find.text('System voice'), findsOneWidget);
    });
  });

  group('unsupported language', () {
    testWidgets("says when the packs don't speak the stream's language",
        (tester) async {
      await open(tester, streamLanguage: 'th', installed: ['en', 'fr']);
      expect(find.text(_unsupportedThai), findsOneWidget);
    });

    testWidgets("isn't shown when a pack speaks it", (tester) async {
      await open(tester, streamLanguage: 'fr', installed: ['en', 'fr']);
      expect(find.textContaining("isn't supported"), findsNothing);
    });

    testWidgets("matches a region's language", (tester) async {
      await open(tester, streamLanguage: 'pt-br', installed: ['pt']);
      expect(find.textContaining("isn't supported"), findsNothing);
    });

    testWidgets("isn't shown without a pack", (tester) async {
      await open(tester, streamLanguage: 'th');
      expect(find.textContaining("isn't supported"), findsNothing);
    });
  });

  group('voice pack suggestion', () {
    const suggestion = 'Try a more natural voice';

    testWidgets("suggests the pack for the stream's language", (tester) async {
      await open(tester, streamLanguage: 'fr', mode: TtsMode.enabled);
      expect(find.text(suggestion), findsOneWidget);
      expect(
          find.text('Supertonic 3 reads French chat with a neural voice that '
              "runs on your device. It's a 401 MB download."),
          findsOneWidget);
    });

    testWidgets("falls back to the device's language", (tester) async {
      await open(tester, streamLanguage: 'th', mode: TtsMode.enabled);
      expect(find.textContaining('reads English chat'), findsOneWidget);
    });

    testWidgets('only while text to speech is on', (tester) async {
      await open(tester, streamLanguage: 'fr');
      expect(find.text(suggestion), findsNothing);
    });

    testWidgets('not once a pack is installed', (tester) async {
      await open(tester, mode: TtsMode.enabled, installed: ['en']);
      expect(find.text(suggestion), findsNothing);
    });

    testWidgets('can be dismissed for good', (tester) async {
      final harness = await open(tester, mode: TtsMode.enabled);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(find.text(suggestion), findsNothing);
      expect(harness.tts.isVoicePackSuggestionDismissed, isTrue);
      expect(harness.tts.toJson()['isVoicePackSuggestionDismissed'], isTrue);
    });

    testWidgets('downloads the pack and shows its progress', (tester) async {
      final harness = await open(tester, mode: TtsMode.enabled);
      await tester.tap(find.bySemanticsLabel('Download Supertonic 3'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(harness.repository.tasks, contains('supertonic-3'));
      expect(find.byType(VoicePacksScreen), findsOneWidget);
      expect(find.text('Waiting for Wi-Fi'), findsOneWidget);
      harness.repository.tasks['supertonic-3']!.cancel();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('works with large text on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(tester,
        streamLanguage: 'th', mode: TtsMode.enabled, installed: ['en']);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Voice packs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voice packs'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('31 languages'), 100);
    await tester.ensureVisible(find.text('31 languages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('31 languages'));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
