import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';

import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';

void main() {
  late FakeVoicePackRepository repository;

  Future<void> open(WidgetTester tester, {String language = 'en'}) async {
    repository = FakeVoicePackRepository();
    final packs = VoicePacksModel(repository, isSupported: true);
    final tts = TtsModel.fromJson(const {},
        engine: FakeTtsEngine(), reportError: (e, st) => throw e)
      ..language = Language(language);
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
        home: VoicePacksScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('lists a pack with its size, license and languages',
      (tester) async {
    await open(tester, language: 'fr');

    expect(find.text('Supertonic 3'), findsOneWidget);
    expect(find.text('10 voices · 401 MB'), findsOneWidget);
    expect(find.text('Storage used: 0 MB'), findsOneWidget);
    expect(find.textContaining('machine-generated'), findsOneWidget);
    expect(find.text('Supertonic 3 by Supertone Inc.'), findsOneWidget);
    expect(find.textContaining('forbids harmful uses'), findsOneWidget);
    expect(find.text('OpenRAIL-M'), findsOneWidget);

    // the stream's language first, then by name.
    expect(find.text('5 languages'), findsOneWidget);
    expect(
        find.text('French, English, German, Japanese, Korean'), findsOneWidget);
    await tap(tester, find.text('5 languages'));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNWidgets(5));
    expect(
        find.descendant(
            of: find.widgetWithText(Chip, 'French'),
            matching: find.byIcon(Icons.live_tv)),
        findsOneWidget);
  });

  testWidgets('an installed pack can be deleted', (tester) async {
    await open(tester);
    repository.add(installedPackOf(testPack(), sizeOnDisk: 402000000));
    await tester.pumpAndSettle();

    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('10 voices · 402 MB'), findsOneWidget);
    expect(find.text('Storage used: 402 MB'), findsOneWidget);

    await tap(tester, find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
        find.text('Delete Supertonic 3? This frees 402 MB.'), findsOneWidget);
    await tap(tester, find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.deleted, isEmpty);

    await tap(tester, find.text('Delete'));
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repository.deleted, ['supertonic-3']);
    expect(find.text('Installed'), findsNothing);
    expect(find.text('Storage used: 0 MB'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });
}
