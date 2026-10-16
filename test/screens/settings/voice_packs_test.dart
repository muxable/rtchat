import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';

import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';

void main() {
  late FakeVoicePackRepository repository;

  Future<void> open(WidgetTester tester,
      {Widget home = const VoicePacksScreen(), bool isSupported = true}) async {
    repository = FakeVoicePackRepository();
    final packs = VoicePacksModel(repository, isSupported: isSupported);
    final tts = TtsModel.fromJson(const {},
        engine: FakeTtsEngine(), reportError: (e, st) => throw e);
    addTearDown(() {
      packs.dispose();
      tts.dispose();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tts),
        ChangeNotifierProvider.value(value: packs),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          LocaleNamesLocalizationsDelegate(),
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('lists a pack with its size, languages and license',
      (tester) async {
    await open(tester);

    expect(find.text('Supertonic 3'), findsOneWidget);
    expect(find.text('10 voices · 401 MB'), findsOneWidget);
    // sorted by name.
    expect(
        find.textContaining(
            RegExp(r'^31 languages: Arabic, Bulgarian, .*, Vietnamese$')),
        findsOneWidget);
    expect(find.textContaining('machine-generated'), findsOneWidget);
    expect(find.text('Supertonic 3 by Supertone Inc.'), findsOneWidget);
    expect(find.textContaining('forbids harmful uses'), findsOneWidget);
    expect(find.text('OpenRAIL-M'), findsOneWidget);

    // the size on disk once installed.
    repository
        .add(installedPackOf(bundledVoicePacks.single, sizeOnDisk: 402000000));
    await tester.pumpAndSettle();
    expect(find.text('10 voices · 402 MB'), findsOneWidget);
  });

  testWidgets('the text to speech settings open it', (tester) async {
    await open(tester, home: const TextToSpeechScreen());
    await tester.tap(find.text('Voice packs'));
    await tester.pumpAndSettle();
    expect(find.text('Supertonic 3'), findsOneWidget);
  });

  testWidgets('hidden where neural voices are unsupported', (tester) async {
    await open(tester, home: const TextToSpeechScreen(), isSupported: false);
    expect(find.text('Voice packs'), findsNothing);
  });

  testWidgets('an installed pack can be deleted', (tester) async {
    await open(tester);
    expect(find.text('Delete'), findsNothing);
    repository
        .add(installedPackOf(bundledVoicePacks.single, sizeOnDisk: 402000000));
    await tester.pumpAndSettle();

    Future<void> tapDelete() async {
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(
          find.text('Delete Supertonic 3? This frees 402 MB.'), findsOneWidget);
    }

    await tapDelete();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);

    await tapDelete();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['supertonic-3']);
    expect(find.text('10 voices · 401 MB'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });
}
