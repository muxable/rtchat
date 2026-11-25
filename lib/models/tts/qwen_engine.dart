import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Runs the bundled WebGPU kernels in the mobile WebView. Model files have
/// already passed the voice pack installer's size and SHA-256 checks.
class QwenTtsEngine implements TtsEngine {
  QwenTtsEngine(this.pack);
  final InstalledVoicePack pack;
  static final view = ValueNotifier<WebViewController?>(null);
  static const _modules = {
    'bridge.mjs',
    'speech.mjs',
    'player.mjs',
    'device.mjs',
    'source.mjs',
    'weights.index',
    'decoder.plan',
    'kernels.mjs',
    'talker.mjs',
    'predictor.mjs',
    'decoder.mjs',
    'tokenizer.mjs',
    'qualification.json',
  };
  static const _languages = {
    'en': 'english',
    'zh': 'chinese',
    'fr': 'french',
    'de': 'german',
    'it': 'italian',
    'ja': 'japanese',
    'ko': 'korean',
    'pt': 'portuguese',
    'ru': 'russian',
    'es': 'spanish',
  };
  final _pending = <int, Completer<void>>{};
  int _sequence = 0, _epoch = 0, _stops = 0;
  bool _disposed = false;
  HttpServer? _server;
  WebViewController? _controller;
  Future<void>? _loading;
  Completer<void>? _ready;

  Future<void> _serve(HttpRequest request, String token) async {
    final res = request.response;
    try {
      final path = request.uri.pathSegments;
      if (request.method != 'GET' ||
          request.headers.host != '127.0.0.1' ||
          path.length < 2 ||
          path.first != token) {
        res.statusCode = HttpStatus.notFound;
      } else if (path.length == 2 && path.last == 'index.html') {
        res.headers.contentType = ContentType.html;
        res.headers.set(
          'Content-Security-Policy',
          "default-src 'none'; script-src 'self'; connect-src 'self'",
        );
        res.write(
          '<!doctype html><meta charset="utf-8"><script type="module" src="./bridge.mjs"></script>',
        );
      } else if (path.length == 2 && _modules.contains(path.last)) {
        res.headers.contentType =
            path.last.endsWith('.mjs')
                ? ContentType('text', 'javascript')
                : ContentType.json;
        res.write(
          await rootBundle.loadString(
            'packages/on_device_tts/assets/qwen/${path.last}',
          ),
        );
      } else if (path.length == 3 &&
          path[1] == 'model' &&
          pack.pack.files.any((f) => f.path == path.last)) {
        final file = File('${pack.directory}/${path.last}');
        final length = await file.length();
        final range = request.headers.value(HttpHeaders.rangeHeader);
        if (range == null) {
          res.contentLength = length;
          await res.addStream(file.openRead());
        } else {
          final match = RegExp(r'^bytes=(\d+)-(\d+)$').firstMatch(range);
          final start = int.tryParse(match?.group(1) ?? '');
          final end = int.tryParse(match?.group(2) ?? '');
          if (start == null || end == null || start > end || end >= length) {
            res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
          } else {
            res.statusCode = HttpStatus.partialContent;
            res.headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-$end/$length',
            );
            res.contentLength = end - start + 1;
            await res.addStream(file.openRead(start, end + 1));
          }
        }
      } else {
        res.statusCode = HttpStatus.notFound;
      }
    } on IOException {
      // The WebView can abandon a streamed model during teardown.
    } finally {
      await res.close().catchError((Object _) {});
    }
  }

  Future<void> _open() async {
    final generation = _epoch;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_disposed || generation != _epoch) {
      await server.close(force: true);
      throw StateError('Qwen load cancelled');
    }
    _server = server;
    final rng = Random.secure();
    final token = base64Url.encode(List.generate(24, (_) => rng.nextInt(256)));
    final page = Uri.parse('http://127.0.0.1:${server.port}/$token/index.html');
    server.listen((request) => unawaited(_serve(request, token)));
    final controller =
        WebViewPlatform.instance is WebKitWebViewPlatform
            ? WebViewController.fromPlatformCreationParams(
              WebKitWebViewControllerCreationParams(
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const {},
              ),
            )
            : WebViewController();
    _controller = controller;
    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      await platform.setMediaPlaybackRequiresUserGesture(false);
    }
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    final ready = _ready = Completer<void>();
    ready.future.ignore();
    await controller.addJavaScriptChannel(
      'QwenSpeech',
      onMessageReceived: (message) {
        final data = jsonDecode(message.message) as Map<String, dynamic>;
        if (data['ready'] == true) {
          if (!ready.isCompleted) ready.complete();
        } else {
          final result = _pending.remove(data['id']);
          if (data['error'] != null) {
            result?.completeError(StateError(data['error'].toString()));
          } else {
            result?.complete();
          }
        }
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest:
            (r) =>
                r.url == page.toString()
                    ? NavigationDecision.navigate
                    : NavigationDecision.prevent,
      ),
    );
    if (generation != _epoch) throw StateError('Qwen load cancelled');
    view.value = controller;
    await controller.loadRequest(page);
    await ready.future.timeout(const Duration(seconds: 30));
    await _request('load');
  }

  Future<void> _request(
    String method, {
    String? text,
    Map<String, String>? options,
  }) async {
    final controller = _controller;
    if (controller == null) throw StateError('Qwen is unavailable');
    final id = ++_sequence;
    final result = _pending[id] = Completer<void>();
    result.future.ignore();
    try {
      final data = jsonEncode({
        'id': id,
        'method': method,
        'text': text,
        'options': options,
      });
      await controller.runJavaScript('void window.qwen($data)');
      await result.future.timeout(const Duration(minutes: 3));
    } finally {
      _pending.remove(id);
    }
  }

  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = TtsEngine.normalRate,
    double pitch = TtsEngine.normalPitch,
    String? language,
  }) async {
    if (_disposed) throw StateError('Qwen has been disposed');
    final epoch = _epoch, stops = _stops;
    try {
      await (_loading ??= _open());
    } catch (_) {
      if (epoch == _epoch) await release();
      rethrow;
    }
    if (_disposed || _epoch != epoch || stops != _stops) return;
    final tag =
        (language ?? voice?.locale ?? 'en').split('-').first.toLowerCase();
    final lang = _languages[tag];
    if (lang == null) throw UnsupportedError('Qwen language $tag');
    await _request(
      'speak',
      text: text,
      options: {
        'speaker': (voice?.id ?? 'ryan').toLowerCase(),
        'language': lang,
      },
    );
  }

  @override
  Future<List<TtsVoice>> voices({String? language}) async => [
    for (final speaker in pack.pack.speakers)
      for (final locale in pack.pack.languages)
        if (language == null ||
            locale == language.split('-').first.toLowerCase())
          TtsVoice(
            id: speaker.name.toLowerCase(),
            name: speaker.name,
            locale: locale,
          ),
  ];

  @override
  Future<void> stop() async {
    // Invalidates a speak waiting for qualification as well as active audio.
    _stops++;
    if (_ready?.isCompleted == true && _controller != null) {
      await _request('stop');
    }
  }

  @override
  Future<void> release() async {
    _epoch++;
    _loading = null;
    final controller = _controller;
    _controller = null;
    if (identical(view.value, controller)) view.value = null;
    final ready = _ready;
    _ready = null;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(StateError('Qwen released'));
    }
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('Qwen released'));
    }
    _pending.clear();
    final server = _server;
    _server = null;
    // Navigating releases device buffers and stops scheduled Web Audio nodes.
    try {
      await controller?.loadHtmlString('<!doctype html><title>Idle</title>');
    } finally {
      await server?.close(force: true);
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await release();
  }
}
