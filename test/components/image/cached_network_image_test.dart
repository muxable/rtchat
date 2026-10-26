import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rtchat/components/chat_history/tokens.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/style.dart';

import '../l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late _ImageCacheManager manager;
  late BaseCacheManager previousManager;
  late MockClient client;
  late Future<http.Response> Function(http.Request) respond;
  late List<http.Request> requests;

  _ImageCacheManager createManager() {
    final manager = _ImageCacheManager(
      Config(
        'image-test',
        repo: JsonCacheInfoRepository.withFile(
          File('${directory.path}/cache.json'),
        ),
        fileSystem: IOFileSystem('image-test'),
        fileService: HttpFileService(httpClient: client),
      ),
    );
    // Run cleanup during pumps rather than leaving its 10s timer pending.
    manager.store.cleanupRunMinInterval = Duration.zero;
    return manager;
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rtchat-images-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
    requests = [];
    respond = (_) async => throw const SocketException('offline');
    client = MockClient((request) {
      requests.add(request);
      return respond(request);
    });
    previousManager = CachedNetworkImageProvider.defaultCacheManager;
    manager = createManager();
    CachedNetworkImageProvider.defaultCacheManager = manager;
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    CachedNetworkImageProvider.defaultCacheManager = previousManager;
    client.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });

  Future<http.Response> imageResponse(String fixture) async =>
      http.Response.bytes(
        await File('test/fixtures/images/$fixture').readAsBytes(),
        200,
        headers: {
          'content-type': 'image/${fixture.split('.').last}',
          'cache-control': 'max-age=86400',
          // Deliberately no ETag: these responses must still be cached.
        },
      );

  Widget chatEmote(Uri url) => MaterialApp(
    home: Material(
      child: Builder(
        builder: (context) {
          final style = StyleModel.fromJson({});
          final spans =
              renderToken(
                context,
                style,
                EmoteToken(url: url, code: 'AnimatedEmote'),
              ).toList();
          style.dispose();
          return Text.rich(TextSpan(children: spans));
        },
      ),
    ),
  );

  for (final format in ['gif', 'webp']) {
    final url = Uri.parse('https://example.com/animated.$format');

    testWidgets(
      '$format animates in chat after download and an offline restart',
      (tester) async {
        respond = (_) => imageResponse('animated.$format');
        await tester.pumpWidget(chatEmote(url));
        await _expectAnimation(tester);
        expect(requests, hasLength(1));
        expect(tester.getSize(find.byType(Image)).height, 20);

        // Reopen persisted cache metadata and clear Flutter's decoded image cache,
        // so this exercises disk bytes rather than an in-memory image or codec.
        await tester.pumpWidget(const SizedBox());
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        await _waitFor(tester, () => manager.webHelper.concurrentCalls == 0);
        await _dispose(tester, manager);
        await tester.runAsync(() async {
          manager = createManager();
          CachedNetworkImageProvider.defaultCacheManager = manager;
        });
        respond = (_) async => throw const SocketException('offline');
        await tester.pumpWidget(chatEmote(url));
        await _expectAnimation(tester);
        expect(requests, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await _dispose(tester, manager);
      },
    );

    testWidgets('$format animates in the emote picker at its existing size', (
      tester,
    ) async {
      respond = (_) => imageResponse('animated.$format');
      await tester.pumpWidget(
        MaterialApp(
          home: TestLocalizations(
            child: Material(
              child: EmotesList(
                emotes: [
                  Emote(
                    provider: '7tv',
                    category: null,
                    id: 'animated',
                    code: 'AnimatedEmote',
                    imageUrl: url.toString(),
                  ),
                ],
                channel: Channel('twitch', '1', 'streamer'),
                onEmoteSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await _expectAnimation(tester);
      // The 36px button's vertical padding constrains its icon to 20px.
      expect(tester.getSize(find.byType(CrossFadeImage)), const Size(36, 20));
      expect(requests, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await _dispose(tester, manager);
    });
  }

  testWidgets('a failed image displays the emote code fallback', (
    tester,
  ) async {
    respond = (_) async => http.Response('', 404);
    await tester.pumpWidget(
      chatEmote(Uri.parse('https://example.com/broken.gif')),
    );
    await _waitFor(
      tester,
      () => find.text('AnimatedEmote').evaluate().isNotEmpty,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await _dispose(tester, manager);
  });
}

// Fixtures are 4x4 two-frame GIF/WebP (red/blue, 100ms, infinite loop).
// Use the same image-cache mixin as DefaultCacheManager, backed by real disk
// files and a local JSON index so tests need no platform SQLite plugin.
class _ImageCacheManager extends CacheManager with ImageCacheManager {
  _ImageCacheManager(super.config);
}

Future<void> _dispose(WidgetTester tester, CacheManager manager) async {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
  // Pump fake microtasks while the disk-backed repository closes.
  var disposed = false;
  unawaited(manager.dispose().then((_) => disposed = true));
  await _waitFor(tester, () => disposed);
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 100 && !ready(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(ready(), isTrue, reason: 'image did not reach the expected state');
}

Future<void> _waitForPixel(WidgetTester tester, List<int> pixel) async {
  List<int>? actual;
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    for (final raw in tester.widgetList<RawImage>(find.byType(RawImage))) {
      final image = raw.image;
      if (image == null || image.width != 4) continue;
      final data = await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      actual = data!.buffer.asUint8List().sublist(0, 4);
      if (actual.toString() == pixel.toString()) return;
    }
  }
  expect(actual, pixel);
}

Future<void> _expectAnimation(WidgetTester tester) async {
  // Check rendered frame pixels and a full loop, not just a successful decode.
  await _waitForPixel(tester, [255, 0, 0, 255]);
  await _waitForPixel(tester, [0, 0, 255, 255]);
  await _waitForPixel(tester, [255, 0, 0, 255]);
}
