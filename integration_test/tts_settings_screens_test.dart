import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/neural_engine_selector.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/themes.dart';

/// Walks through the text to speech settings on a device with the real
/// voice pack repository and engines, without signing in: suggests a voice
/// pack, installs Supertonic 3 through the UI (about 400 MB from Hugging
/// Face, so it only runs when asked to), picks and previews voices, and
/// deletes the pack again.
///
///     flutter test integration_test/tts_settings_screens_test.dart \
///       -d emulator-5554 --dart-define=TTS_SETTINGS_WALKTHROUGH=true
///
/// It prints `SCREEN: <name>` and holds each screen for a few seconds, for
/// taking screenshots from the host (`adb exec-out screencap -p`).
/// `--dart-define=VOICE_PACK_KEEP=true` keeps the pack installed.
const _run = bool.fromEnvironment('TTS_SETTINGS_WALKTHROUGH');
const _keep = bool.fromEnvironment('VOICE_PACK_KEEP');
const _hold = Duration(seconds: 4);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('text to speech settings walkthrough', (tester) async {
    final support = await getApplicationSupportDirectory();
    final repository = VoicePackRepository(
        directory: Directory('${support.path}/voice_packs'));
    await repository.delete('supertonic-3');
    final tts = TtsModel.fromJson(const {});
    final l10n = lookupAppLocalizations(const Locale('en'));
    tts.language = Language('fr');
    tts.setMode(l10n, TtsMode.enabled);
    final selector = NeuralEngineSelector(repository: repository, tts: tts);
    await selector.start();
    final packs = VoicePacksModel(repository);
    final theme = ValueNotifier(ThemeMode.light);
    final textScale = ValueNotifier(1.0);

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tts),
        ChangeNotifierProvider.value(value: packs),
      ],
      child: ListenableBuilder(
        listenable: Listenable.merge([theme, textScale]),
        builder: (context, child) => MaterialApp(
          theme: Themes.lightTheme,
          darkTheme: Themes.darkTheme,
          themeMode: theme.value,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale.value)),
            child: child!,
          ),
          home: const TextToSpeechScreen(),
        ),
      ),
    ));

    Future<void> settle([Duration wait = const Duration(seconds: 1)]) async {
      await Future<void>.delayed(wait);
      await tester.pump();
    }

    Future<void> screen(String name) async {
      await settle();
      debugPrint('SCREEN: $name');
      await settle(_hold);
    }

    Future<void> tap(Finder finder) async {
      for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await settle(const Duration(milliseconds: 300));
      }
      await tester.ensureVisible(finder);
      await settle();
      await tester.tap(finder);
      await settle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await settle();
    }

    await settle(const Duration(seconds: 2));
    expect(find.text('Try a more natural voice'), findsOneWidget);
    await screen('tts-settings-suggestion');
    theme.value = ThemeMode.dark;
    await screen('tts-settings-suggestion-dark');
    theme.value = ThemeMode.light;

    await tap(find.text('Voice packs'));
    await tap(find.text('31 languages'));
    await screen('voice-packs-languages');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await screen('voice-packs-languages-scrolled');
    theme.value = ThemeMode.dark;
    await screen('voice-packs-languages-dark');
    theme.value = ThemeMode.light;

    await tap(find.text('Download'));
    final task = repository.task('supertonic-3')!;
    final phases = <VoicePackInstallPhase>{};
    task.progress.listen((progress) => phases.add(progress.phase));
    await screen('voice-pack-install-waiting');
    final installed = Completer<void>();
    task.done.then((_) => installed.complete(),
        onError: (Object e, StackTrace st) => installed.completeError(e, st));
    var shotProgress = false;
    final watch = Stopwatch()..start();
    while (!installed.isCompleted) {
      await settle();
      final latest = task.latest;
      if (!shotProgress &&
          latest.phase == VoicePackInstallPhase.downloading &&
          latest.fraction > 0.2) {
        shotProgress = true;
        await screen('voice-pack-install-progress');
      }
      if (watch.elapsed > const Duration(minutes: 25)) {
        fail('the install took too long: ${task.latest}');
      }
    }
    await installed.future;
    debugPrint('installed in ${watch.elapsed}, phases $phases');
    await settle(const Duration(seconds: 2));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await screen('voice-packs-installed');

    await back();
    await screen('tts-settings-neural');
    tts.language = Language('th');
    await screen('tts-settings-unsupported-language');
    theme.value = ThemeMode.dark;
    await screen('tts-settings-unsupported-language-dark');
    theme.value = ThemeMode.light;
    textScale.value = 1.6;
    await screen('tts-settings-large-text');
    textScale.value = 1.0;
    tts.language = Language('fr');

    await tap(find.text('Voices'));
    await screen('voice-languages');
    await tap(find.text('French'));
    await screen('voice-picker');
    await tap(find.text('M2'));
    expect((await tts.voiceFor('fr'))!.id, 'M2');
    await tap(find.byTooltip('Play a sample of M2'));
    await screen('voice-picker-preview');
    // the model loads on first use, so give the sample time to play.
    final playing = find.descendant(
        of: find.byType(RadioListTile<String>),
        matching: find.byType(CircularProgressIndicator));
    for (var i = 0; i < 60 && playing.evaluate().isNotEmpty; i++) {
      await settle();
    }
    expect(playing, findsNothing);
    expect(find.text("Couldn't play the sample"), findsNothing);
    theme.value = ThemeMode.dark;
    await screen('voice-picker-dark');
    theme.value = ThemeMode.light;
    await back();
    await back();

    if (!_keep) {
      await tap(find.text('Voice packs'));
      await tap(find.text('Delete'));
      await screen('voice-pack-delete-confirm');
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await settle(const Duration(seconds: 2));
      expect(await repository.installedPack('supertonic-3'), isNull);
      await screen('voice-packs-deleted');
    }

    selector.dispose();
    packs.dispose();
    tts.dispose();
    await repository.dispose();
  }, skip: !_run, timeout: const Timeout(Duration(minutes: 40)));
}
