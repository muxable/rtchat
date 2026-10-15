import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/screens/settings/tts/voice_packs.dart';

import '../../fakes/fake_voice_pack_repository.dart';
import 'tts_harness.dart';

/// Scrolls [finder] into view and taps it.
Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

void main() {
  Future<TtsHarness> open(WidgetTester tester,
      {String streamLanguage = 'en', void Function(TtsHarness)? setUp}) async {
    final harness = TtsHarness(streamLanguage: streamLanguage);
    setUp?.call(harness);
    await tester.pumpWidget(harness.app(const VoicePacksScreen()));
    await tester.pumpAndSettle();
    return harness;
  }

  FakeInstallTask taskOf(TtsHarness harness) =>
      harness.repository.tasks['supertonic-3']!;

  testWidgets('lists each pack with its size, license and languages',
      (tester) async {
    await open(tester, streamLanguage: 'fr');

    expect(find.text('Supertonic 3'), findsOneWidget);
    expect(find.text('10 voices · 401 MB download'), findsOneWidget);
    expect(find.text('License: OpenRAIL-M'), findsOneWidget);
    expect(find.text('Supertonic 3 by Supertone Inc.'), findsOneWidget);
    expect(find.textContaining('OpenRAIL-M) forbids harmful uses'),
        findsOneWidget);
    expect(find.textContaining('machine-generated'), findsOneWidget);
    expect(find.text('Storage used: 0 MB'), findsOneWidget);

    // collapsed: how many, and the first names, the stream's first.
    expect(find.text('31 languages'), findsOneWidget);
    final summary = tester
        .widget<Text>(find.textContaining('French, Arabic, Bulgarian'))
        .data!;
    expect(summary, startsWith('French, Arabic, Bulgarian, Croatian'));
    expect(find.byType(Chip), findsNothing);

    // expanded: every language by its name, the stream's marked.
    await tap(tester, find.text('31 languages'));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNWidgets(31));
    for (final name in ['English', 'Korean', 'Japanese', 'Vietnamese']) {
      expect(find.widgetWithText(Chip, name), findsOneWidget, reason: name);
    }
    expect(find.bySemanticsLabel('French, Stream language'), findsOneWidget);
    expect(
        find.descendant(
            of: find.widgetWithText(Chip, 'French'),
            matching: find.byIcon(Icons.live_tv)),
        findsOneWidget);
  });

  testWidgets('shows install progress, waiting for Wi-Fi, and cancels',
      (tester) async {
    final harness = await open(tester);

    await tap(tester, find.bySemanticsLabel('Download Supertonic 3'));
    await tester.pump();
    final task = taskOf(harness);
    expect(task.allowMetered, isFalse);
    expect(find.text('Waiting for Wi-Fi'), findsOneWidget);
    expect(find.text('Use mobile data'), findsOneWidget);
    expect(find.bySemanticsLabel('Download Supertonic 3'), findsNothing);

    task.emit(VoicePackInstallPhase.downloading, 100000000);
    await tester.pump();
    expect(find.text('Downloading: 100 MB of 401 MB'), findsOneWidget);
    expect(find.text('Waiting for Wi-Fi'), findsNothing);
    final bar = tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(100 / 401, 0.001));
    expect(
        tester.getSemantics(
            find.bySemanticsLabel('Supertonic 3 download progress')),
        matchesSemantics(
            label: 'Supertonic 3 download progress', value: '25%'));

    task.emit(VoicePackInstallPhase.verifying, 401000000);
    await tester.pump();
    expect(find.text('Checking the download'), findsOneWidget);

    await tap(tester, find.byTooltip('Cancel downloading Supertonic 3'));
    await tester.pumpAndSettle();
    expect(task.isCancelled, isTrue);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel('Download Supertonic 3'), findsOneWidget);
    // cancelling isn't an error.
    expect(find.textContaining("Couldn't install"), findsNothing);
  });

  testWidgets('a download waiting for Wi-Fi can switch to mobile data',
      (tester) async {
    final harness = await open(tester);
    await tap(tester, find.bySemanticsLabel('Download Supertonic 3'));
    await tester.pump();
    final first = taskOf(harness);

    await tap(tester, find.text('Use mobile data'));
    // the old install ends before the new one starts.
    await tester.pump();
    await tester.pump();
    expect(first.isCancelled, isTrue);
    final second = taskOf(harness);
    expect(second, isNot(same(first)));
    expect(second.allowMetered, isTrue);
    expect(find.text('Waiting to download'), findsOneWidget);
    expect(find.text('Use mobile data'), findsNothing);
  });

  testWidgets('allowing mobile data applies to new downloads', (tester) async {
    final harness = await open(tester);
    await tap(tester, find.text('Download over mobile data'));
    await tester.pump();
    expect(harness.packs.allowMobileData, isTrue);

    await tap(tester, find.bySemanticsLabel('Download Supertonic 3'));
    await tester.pump();
    expect(taskOf(harness).allowMetered, isTrue);
    expect(find.text('Waiting to download'), findsOneWidget);
  });

  testWidgets('an installed pack shows its size and can be deleted',
      (tester) async {
    final harness = await open(tester);
    await tap(tester, find.bySemanticsLabel('Download Supertonic 3'));
    await tester.pump();
    harness.repository.completeInstall('supertonic-3');
    await tester.pumpAndSettle();

    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('10 voices · 401 MB download · 402 MB on device'),
        findsOneWidget);
    expect(find.text('Storage used: 402 MB'), findsOneWidget);
    expect(find.bySemanticsLabel('Download Supertonic 3'), findsNothing);

    await tap(tester, find.bySemanticsLabel('Delete Supertonic 3'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Supertonic 3?'), findsOneWidget);
    expect(find.textContaining('This frees 402 MB.'), findsOneWidget);

    // cancelling the dialog keeps the pack.
    await tap(tester, find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(harness.repository.deleted, isEmpty);

    await tap(tester, find.bySemanticsLabel('Delete Supertonic 3'));
    await tester.pumpAndSettle();
    await tap(tester, find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(harness.repository.deleted, ['supertonic-3']);
    expect(find.text('Installed'), findsNothing);
    expect(find.text('Storage used: 0 MB'), findsOneWidget);
    expect(find.bySemanticsLabel('Download Supertonic 3'), findsOneWidget);
  });

  testWidgets('a failed install says why and can be tried again',
      (tester) async {
    final harness = await open(tester);
    await tap(tester, find.bySemanticsLabel('Download Supertonic 3'));
    await tester.pump();
    taskOf(harness).fail(const VoicePackDownloadException('boom'));
    await tester.pumpAndSettle();

    expect(
        find.text("Couldn't install Supertonic 3: the download failed; "
            'check your connection and try again'),
        findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tap(tester, find.text('Try again'));
    await tester.pump();
    expect(harness.repository.tasks, contains('supertonic-3'));
    expect(find.textContaining("Couldn't install"), findsNothing);
  });

  testWidgets('says when the catalog cannot be read', (tester) async {
    final harness = await open(tester,
        setUp: (harness) => harness.repository.catalogError = Exception('x'));
    expect(find.text("Couldn't load the voice packs"), findsOneWidget);

    harness.repository.catalogError = null;
    await tap(tester, find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Supertonic 3'), findsOneWidget);
  });

  testWidgets('lists every pack in the catalog', (tester) async {
    await open(tester,
        setUp: (harness) => harness.repository.catalogPacks = [
              testPack(),
              testPack(
                  id: 'english',
                  name: 'English voices',
                  languages: ['en-US'],
                  size: 80000000),
            ]);
    expect(find.text('Supertonic 3'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('1 language'), 200);
    expect(find.text('English voices'), findsOneWidget);
    expect(find.text('10 voices · 80 MB download'), findsOneWidget);
  });
}
