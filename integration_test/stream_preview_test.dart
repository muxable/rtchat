// Run on Android or iOS with a currently live channel, for example:
// flutter test integration_test/stream_preview_test.dart -d <device> \
//   --dart-define=PREVIEW_TWITCH_CHANNEL_ID=<numeric-id> \
//   --dart-define=PREVIEW_KICK_CHANNEL_ID=<numeric-id>
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/stream_preview.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

Future<Map<String, dynamic>> playerState(
  PlatformWebViewController controller,
) async {
  Object? result = await controller.runJavaScriptReturningResult('''
    JSON.stringify({
      url: location.href,
      text: document.body?.innerText,
      videos: Array.from(document.querySelectorAll('video')).map(v => ({
        paused: v.paused, time: v.currentTime, ready: v.readyState,
        muted: v.muted, volume: v.volume, error: v.error?.message
      }))
    })
  ''');
  // Android returns a JSON-encoded string; WebKit returns the string itself.
  while (result is String) {
    result = jsonDecode(result);
  }
  if (result is! Map) return {'videos': <dynamic>[]};
  return Map<String, dynamic>.from(result);
}

Future<void> expectPlayback(
  WidgetTester tester,
  PlatformWebViewController controller,
) async {
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  double? previousTime;
  Map<String, dynamic>? state;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(seconds: 2));
    try {
      state = await playerState(controller);
    } on PlatformException catch (error) {
      // Navigating between the redirect and player can invalidate an evaluation.
      state = {'error': error.message};
      continue;
    }
    final videos = state['videos'] as List;
    for (final video in videos) {
      final time = (video['time'] as num).toDouble();
      if (video['paused'] == false && (video['ready'] as num) >= 2) {
        if (previousTime != null && time > previousTime + 0.5) {
          debugPrint('Preview playback verified: $state');
          return;
        }
        previousTime = time;
      }
    }
  }
  fail('Video did not advance within 3 minutes: $state');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channels = {
    Providers.twitch: String.fromEnvironment('PREVIEW_TWITCH_CHANNEL_ID'),
    Providers.kick: String.fromEnvironment('PREVIEW_KICK_CHANNEL_ID'),
  };
  for (final entry in channels.entries) {
    testWidgets('mobile ${entry.key} preview plays and closes', (tester) async {
      final model = StreamPreviewModel.fromJson({'showBatteryPrompt': false});
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: model,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                // Match the small portrait preview, where Twitch disables autoplay.
                child: SizedBox(
                  width: 320,
                  height: 180,
                  child: StreamPreview(
                    channel: Channel(entry.key, entry.value, entry.value),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final controller =
          tester
              .widget<WebViewWidget>(find.byType(WebViewWidget))
              .platform
              .params
              .controller;
      await expectPlayback(tester, controller);
      if (entry.key == Providers.twitch) {
        // The Flutter controls must remain usable after playback starts.
        expect(find.byIcon(Icons.volume_mute), findsOneWidget);
        await tester.tap(find.byType(StreamPreview));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byIcon(Icons.volume_mute));
        await tester.pump(const Duration(seconds: 2));
        expect(model.volume, 100);
        final video = ((await playerState(controller))['videos'] as List).first;
        expect(video['muted'], false);
        await expectPlayback(tester, controller);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      if (Platform.isIOS) {
        expect(
          (await playerState(controller))['videos'],
          isEmpty,
          reason: 'Closing the iOS preview must stop its media',
        );
      }
      model.dispose();
    }, skip: entry.value.isEmpty);
  }
}
