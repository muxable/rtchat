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
  late TtsModel tts;

  Future<void> open(
    WidgetTester tester, {
    Widget home = const VoicePacksScreen(),
    bool isSupported = true,
    List<VoicePack>? catalog,
  }) async {
    repository =
        FakeVoicePackRepository()
          ..catalog =
              catalog ??
              [
                bundledVoicePacks.singleWhere(
                  (pack) => pack.id == 'supertonic-3',
                ),
              ];
    final packs = VoicePacksModel(repository, isSupported: isSupported);
    tts = TtsModel.fromJson(
      const {},
      engine: FakeTtsEngine(),
      reportError: (e, st) => throw e,
    );
    addTearDown(() {
      packs.dispose();
      tts.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  FakeInstallTask task() => repository.tasks['supertonic-3']!;

  testWidgets('lists a pack with its size, languages and license', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Supertonic 3'), findsOneWidget);
    expect(find.text('10 voices · 401 MB'), findsOneWidget);
    // sorted by name.
    expect(
      find.textContaining(
        RegExp(r'^31 languages: Arabic, Bulgarian, .*, Vietnamese$'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('machine-generated'), findsOneWidget);
    expect(find.text('Supertonic 3 by Supertone Inc.'), findsOneWidget);
    expect(find.textContaining('forbids harmful uses'), findsOneWidget);
    expect(find.text('OpenRAIL-M'), findsOneWidget);

    // the size on disk once installed.
    repository.add(
      installedPackOf(
        bundledVoicePacks.singleWhere((pack) => pack.id == 'supertonic-3'),
        sizeOnDisk: 402000000,
      ),
    );
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

  testWidgets('shows progress, waits for Wi-Fi, and cancels', (tester) async {
    await open(tester);

    await tap(tester, find.text('Download'));
    expect(task().allowMetered, isFalse);
    expect(find.text('Waiting for Wi-Fi'), findsOneWidget);
    expect(find.text('Download'), findsNothing);

    task().emit(VoicePackInstallPhase.downloading, 100000000);
    await tester.pump();
    expect(find.text('Downloading: 100 MB of 401 MB'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(100 / 401, 0.001),
    );

    task().emit(VoicePackInstallPhase.verifying, 401000000);
    await tester.pump();
    expect(find.text('Installing'), findsOneWidget);

    final cancelled = task();
    await tap(tester, find.byTooltip('Cancel'));
    await tester.pumpAndSettle();
    expect(cancelled.isCancelled, isTrue);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Download'), findsOneWidget);
    // cancelling isn't an error.
    expect(find.textContaining("Couldn't install"), findsNothing);
  });

  testWidgets('a download waiting for Wi-Fi can use mobile data', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text('Download'));
    final first = task();

    await tap(tester, find.text('Use mobile data'));
    await tester.pump();
    expect(first.isCancelled, isTrue);
    expect(task(), isNot(same(first)));
    expect(task().allowMetered, isTrue);
    expect(find.text('Downloading: 0 MB of 401 MB'), findsOneWidget);
    expect(find.text('Use mobile data'), findsNothing);
  });

  testWidgets('an installed pack can be deleted', (tester) async {
    await open(tester);
    expect(find.text('Delete'), findsNothing);
    await tap(tester, find.text('Download'));
    repository.completeInstall('supertonic-3');
    await tester.pumpAndSettle();
    expect(find.text('10 voices · 402 MB'), findsOneWidget);
    expect(find.text('Download'), findsNothing);

    Future<void> tapDelete() async {
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(
        find.text('Delete Supertonic 3? This frees 402 MB.'),
        findsOneWidget,
      );
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
    expect(find.text('Download'), findsOneWidget);
  });

  testWidgets('a failed install says so and can be tried again', (
    tester,
  ) async {
    await open(tester);
    await tap(tester, find.text('Download'));
    task().fail(const VoicePackDownloadException('boom'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Couldn't install Supertonic 3. Check your connection and try again.",
      ),
      findsOneWidget,
    );

    await tap(tester, find.text('Download'));
    expect(repository.tasks, contains('supertonic-3'));
    expect(find.textContaining("Couldn't install"), findsNothing);
  });

  testWidgets('offers an update for an outdated pack', (tester) async {
    await open(tester);
    final pack = bundledVoicePacks.singleWhere(
      (pack) => pack.id == 'supertonic-3',
    );
    repository.add(installedPackOf(pack));
    repository.catalog = [
      VoicePack.fromJson({...pack.toJson(), 'version': 2}),
    ];
    await tester.pumpAndSettle();

    await tap(tester, find.text('Update'));
    expect(repository.tasks, contains('supertonic-3'));
  });
  testWidgets('lists both packs and selects the installed pack explicitly', (
    tester,
  ) async {
    await open(tester, catalog: bundledVoicePacks);
    final current = bundledVoicePacks.singleWhere(
      (pack) => pack.id == 'supertonic-3',
    );
    final smaller = bundledVoicePacks.singleWhere(
      (pack) => pack.id == 'supertonic-2',
    );
    repository.add(installedPackOf(current));
    repository.add(installedPackOf(smaller));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      current.id,
    );
    await tester.scrollUntilVisible(
      find.text('Supertonic 2'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tap(tester, find.text('Supertonic 2'));
    await tester.pumpAndSettle();
    expect(tts.preferredVoicePackId, smaller.id);
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      smaller.id,
    );
  });
}
