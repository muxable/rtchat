import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/screens/settings/tts/fallback_notice.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';

import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';
import 'tts_harness.dart';

const _lowMemoryBody = "This device doesn't have enough memory for neural "
    "voices, so chat is read with your phone's system voice.";
const _loadFailedBody = "The neural voice couldn't be loaded, so chat is "
    "read with your phone's system voice until the app restarts.";
const _lowMemorySnackBar =
    'Not enough memory for neural voices: chat is read with the system voice';
const _loadFailedSnackBar =
    "The neural voice couldn't start: chat is read with the system voice";
const _lowMemoryCard =
    "This device doesn't have enough memory for neural voices";

void main() {
  TtsHarness installed({TtsMode mode = TtsMode.disabled}) {
    final harness = TtsHarness(mode: mode);
    harness.repository.add(testPack(languages: ['en']));
    harness.addEngine(['en']);
    return harness;
  }

  group('settings banner', () {
    testWidgets('is shown once, until acknowledged', (tester) async {
      final harness = installed();
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      await tester.pumpWidget(harness.app(const TextToSpeechScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Using the system voice'), findsOneWidget);
      expect(find.text(_lowMemoryBody), findsOneWidget);
      // the engine row agrees.
      expect(find.text('System voice'), findsOneWidget);
      expect(find.text('Neural voice (on-device)'), findsNothing);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text(_lowMemoryBody), findsNothing);
      expect(harness.tts.isNeuralFallbackNoticePending, isFalse);

      // not when the screen opens again.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(harness.app(const TextToSpeechScreen()));
      await tester.pumpAndSettle();
      expect(find.text(_lowMemoryBody), findsNothing);
      expect(find.text('System voice'), findsOneWidget);

      // nor in the next session: the acknowledgement is saved.
      final json = harness.tts.toJson();
      expect(json['acknowledgedNeuralFallbacks'], ['lowMemoryDevice']);
      final next = TtsModel.fromJson(json, engine: FakeTtsEngine());
      addTearDown(next.dispose);
      next.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      expect(next.isNeuralFallbackNoticePending, isFalse);
      // a different reason is still told.
      final other = TtsModel.fromJson(json, engine: FakeTtsEngine());
      addTearDown(other.dispose);
      other.fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      expect(other.isNeuralFallbackNoticePending, isTrue);
    });

    testWidgets('explains a failed load differently', (tester) async {
      final harness = installed();
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      await tester.pumpWidget(harness.app(const TextToSpeechScreen()));
      await tester.pumpAndSettle();
      expect(find.text("Neural voice couldn't start"), findsOneWidget);
      expect(find.text(_loadFailedBody), findsOneWidget);
      expect(find.text(_lowMemoryBody), findsNothing);
    });

    testWidgets('is not shown without a fallback', (tester) async {
      final harness = installed();
      await tester.pumpWidget(harness.app(const TextToSpeechScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Got it'), findsNothing);
      expect(find.text('Neural voice (on-device)'), findsOneWidget);
    });
  });

  group('chat screen snack bar', () {
    Widget chat(TtsHarness harness) => harness.app(
          const NeuralFallbackSnackBarListener(
            child: Scaffold(body: Text('chat')),
          ),
        );

    testWidgets('is shown once while text to speech is on', (tester) async {
      final harness = installed(mode: TtsMode.enabled);
      await tester.pumpWidget(chat(harness));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      await tester.pumpAndSettle();
      expect(find.text(_loadFailedSnackBar), findsOneWidget);
      expect(harness.tts.isNeuralFallbackNoticePending, isTrue);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(harness.tts.isNeuralFallbackNoticePending, isFalse);

      // the same failure again (after new packs) isn't told twice.
      harness.addEngine(['en', 'fr']);
      expect(harness.tts.neuralFallback, isNull);
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('counts as told once it times out', (tester) async {
      final harness = installed(mode: TtsMode.enabled);
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      await tester.pumpWidget(chat(harness));
      await tester.pumpAndSettle();
      expect(find.text(_lowMemorySnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(harness.tts.isNeuralFallbackNoticePending, isFalse);
    });

    testWidgets('waits for text to speech to be turned on', (tester) async {
      final harness = installed();
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      await tester.pumpWidget(chat(harness));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      harness.tts.setMode(l10n, TtsMode.enabled);
      // the model tells its listeners on the next frame.
      tester.binding.scheduleFrame();
      await tester.pumpAndSettle();
      expect(find.text(_lowMemorySnackBar), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    });

    testWidgets('is not shown without a voice pack', (tester) async {
      final harness = TtsHarness(mode: TtsMode.enabled);
      harness.tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
      await tester.pumpWidget(chat(harness));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      // the settings still say so.
      expect(harness.tts.isNeuralFallbackNoticePending, isTrue);
    });
  });

  testWidgets('voice pack cards say the device lacks memory', (tester) async {
    final harness = TtsHarness();
    harness.tts.fallBackToSystemVoices(NeuralTtsFallback.lowMemoryDevice);
    await tester.pumpWidget(harness.app(const VoicePacksScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(_lowMemoryCard), 100);
    expect(find.text(_lowMemoryCard), findsOneWidget);
    // acknowledging the notice doesn't change the device.
    harness.tts.acknowledgeNeuralFallback();
    await tester.pumpAndSettle();
    expect(find.text(_lowMemoryCard), findsOneWidget);
  });
}
