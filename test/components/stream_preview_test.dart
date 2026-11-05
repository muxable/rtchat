import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/stream_preview.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/stream_preview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class PreviewPlatform extends AndroidWebViewPlatform {
  late PreviewController controller;

  @override
  PreviewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => controller = PreviewController(params);

  @override
  PreviewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => PreviewWidget(params);

  @override
  PreviewNavigation createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => PreviewNavigation(params);
}

class PreviewController extends PlatformWebViewController
    implements AndroidWebViewController {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<void> setMediaPlaybackRequiresUserGesture(bool require) async {}

  PreviewController(super.params) : super.implementation();

  JavaScriptChannelParams? channel;
  PlatformNavigationDelegate? navigation;
  final requests = <Uri>[];

  @override
  Future<void> setJavaScriptMode(JavaScriptMode mode) async {}
  @override
  Future<void> enableZoom(bool enabled) async {}
  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    channel = params;
  }

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate delegate,
  ) async {
    navigation = delegate;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    // A fast page can send messages as soon as navigation starts.
    expect(channel, isNotNull);
    expect(navigation, isNotNull);
    requests.add(params.uri);
  }
}

class PreviewWidget extends PlatformWebViewWidget
    implements AndroidWebViewWidget {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  PreviewWidget(super.params) : super.implementation();
  @override
  Widget build(BuildContext context) => const SizedBox();
}

class PreviewNavigation extends PlatformNavigationDelegate
    implements AndroidNavigationDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  PreviewNavigation(super.params) : super.implementation();
  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {}
}

void main() {
  late PreviewPlatform platform;
  setUp(() {
    platform = PreviewPlatform();
    WebViewPlatform.instance = platform;
  });

  Widget preview(String id) => ChangeNotifierProvider(
    create: (_) => StreamPreviewModel.fromJson({'showBatteryPrompt': false}),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StreamPreview(channel: Channel(Providers.twitch, id, id)),
    ),
  );

  testWidgets('configures the bridge and callbacks before loading', (
    tester,
  ) async {
    await tester.pumpWidget(preview('1'));
    await tester.pump();
    expect(
      platform.controller.requests.single,
      Channel(Providers.twitch, '1', '1').embedUri,
    );
  });

  testWidgets('unrelated events do not hide a playing stream', (tester) async {
    await tester.pumpWidget(preview('1'));
    await tester.pump();
    final callback = platform.controller.channel!.onMessageReceived;
    callback(
      const JavaScriptMessage(message: '{"params":{"playback":"Playing"}}'),
    );
    await tester.pump();
    expect(find.text('Loading...'), findsNothing);
    expect(find.byIcon(Icons.volume_mute), findsOneWidget);
    callback(const JavaScriptMessage(message: '{"params":{}}'));
    await tester.pump();
    expect(find.byIcon(Icons.volume_mute), findsOneWidget);
  });

  testWidgets('offline messages remain visible through idle updates', (
    tester,
  ) async {
    await tester.pumpWidget(preview('1'));
    await tester.pump();
    final callback = platform.controller.channel!.onMessageReceived;
    callback(
      const JavaScriptMessage(
        message:
            '{"namespace":"twitch-embed","eventName":"offline","params":{}}',
      ),
    );
    await tester.pump();
    expect(find.byType(Positioned), findsNothing);
    callback(
      const JavaScriptMessage(message: '{"params":{"playback":"Idle"}}'),
    );
    await tester.pump();
    expect(find.byType(Positioned), findsNothing);
  });

  testWidgets('switching channels clears the previous player controls', (
    tester,
  ) async {
    await tester.pumpWidget(preview('1'));
    await tester.pump();
    platform.controller.channel!.onMessageReceived(
      const JavaScriptMessage(message: '{"params":{"playback":"Playing"}}'),
    );
    await tester.pump();
    expect(find.byIcon(Icons.volume_mute), findsOneWidget);
    await tester.pumpWidget(preview('2'));
    await tester.pump();
    expect(find.byIcon(Icons.volume_mute), findsNothing);
    expect(
      platform.controller.requests.map(
        (uri) => uri.queryParameters['channelId'],
      ),
      ['1', '2'],
    );
  });
}
