import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/screens/settings/tts/voices.dart';

import '../../fakes/fake_voice_pack_repository.dart';
import 'tts_harness.dart';

void main() {
  testWidgets('lists the languages of the installed packs, stream first',
      (tester) async {
    final harness = TtsHarness(streamLanguage: 'fr');
    harness.addEngine(['en', 'fr', 'ja']);
    await tester.pumpWidget(harness.app(const VoiceLanguagesScreen()));
    await tester.pumpAndSettle();

    final tiles = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((tile) => (tile.title as Text?)?.data)
        .whereType<String>()
        .toList();
    expect(tiles, ['Per-viewer voice', 'French', 'English', 'Japanese']);
    expect(find.text('Stream language · F1'), findsOneWidget);
    expect(find.text('F1'), findsNWidgets(2));
  });

  testWidgets('without a voice pack there are no voices to pick',
      (tester) async {
    final harness = TtsHarness();
    await tester.pumpWidget(harness.app(const VoiceLanguagesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Download a voice pack to pick voices'), findsOneWidget);
  });

  testWidgets('picking a voice sets it for the language', (tester) async {
    final harness = TtsHarness(streamLanguage: 'fr');
    harness.addEngine(['en', 'fr']);
    harness.repository.add(testPack(languages: ['en', 'fr']));
    await harness.packs.load();
    await tester.pumpWidget(harness.app(const VoiceLanguagesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('French'));
    await tester.pumpAndSettle();
    expect(find.text('French'), findsOneWidget); // the app bar.
    expect(find.byType(RadioListTile<String>), findsNWidgets(10));
    expect(find.text('Female'), findsNWidgets(5));
    expect(find.text('Male'), findsNWidgets(5));

    await tester.ensureVisible(find.text('M2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('M2'));
    await tester.pumpAndSettle();
    expect((await harness.tts.voiceFor('fr'))!.id, 'M2');
    expect(harness.tts.toJson()['neuralVoices'], {'fr': 'M2'});
    // other languages keep theirs.
    expect((await harness.tts.voiceFor('en'))!.id, 'F1');
    final radio =
        tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(radio.groupValue, 'M2');

    // and the language list shows it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Stream language · M2'), findsOneWidget);
  });

  testWidgets('the play button reads a sample in the language with the voice',
      (tester) async {
    final harness = TtsHarness();
    final engine = harness.addEngine(['en', 'fr']);
    await tester
        .pumpWidget(harness.app(const VoicePickerScreen(language: 'fr')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play a sample of F3'));
    await tester.pumpAndSettle();
    final utterance = engine.utterances.single;
    expect(utterance.text, 'Bonjour ! Voici à quoi ressemble ma voix.');
    expect(utterance.voice?.id, 'F3');
    expect(utterance.language, 'fr');
    // previewing doesn't pick the voice.
    expect((await harness.tts.voiceFor('fr'))!.id, 'F1');
  });

  testWidgets('says when the sample could not be played', (tester) async {
    final harness = TtsHarness();
    final engine = harness.addEngine(['en']);
    engine.failNext = Exception('no model');
    await tester
        .pumpWidget(harness.app(const VoicePickerScreen(language: 'en')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Play a sample of F1'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't play the sample"), findsOneWidget);
  });

  testWidgets('per-viewer voice explains that picks apply to alerts',
      (tester) async {
    final harness = TtsHarness();
    harness.addEngine(['en']);
    await tester
        .pumpWidget(harness.app(const VoicePickerScreen(language: 'en')));
    await tester.pumpAndSettle();

    const onText = 'Each viewer gets their own voice. The voices you pick '
        'read alerts and system messages.';
    expect(harness.tts.isRandomVoiceEnabled, isTrue);
    // once, as the switch's subtitle.
    expect(find.text(onText), findsOneWidget);

    await tester.tap(find.text('Per-viewer voice'));
    await tester.pumpAndSettle();
    expect(harness.tts.isRandomVoiceEnabled, isFalse);
    expect(find.text(onText), findsNothing);
    expect(find.text('The voices you pick read everything'), findsOneWidget);
  });
}
