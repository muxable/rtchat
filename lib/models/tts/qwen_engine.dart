import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'qwen_asset_server.dart';

/// Runs the bundled WebGPU kernels in the mobile WebView. Model files have
/// already passed the voice pack installer's size and SHA-256 checks.
class QwenTtsEngine implements TtsEngine {
  QwenTtsEngine(this.pack);
  final InstalledVoicePack pack;
  Map<String, dynamic>? qualification;
  final unavailable = ValueNotifier<String?>(null);
  static final view = ValueNotifier<WebViewController?>(null);
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
  QwenAssetServer? _server;
  WebViewController? _controller;
  Future<void>? _loading;
  Completer<void>? _ready;

  Future<void> _open() async {
    final generation = _epoch;
    final server = await QwenAssetServer.open(pack);
    if (_disposed || generation != _epoch) {
      await server.close();
      throw StateError('Qwen load cancelled');
    }
    _server = server;
    final page = server.page;
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
          if (data['metrics'] case final Map<String, dynamic> metrics) {
            qualification = metrics;
          }
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

  /// Opens and qualifies the accelerator as soon as chat speech is enabled.
  Future<void> prepare() {
    if (_disposed) return Future.error(StateError('Qwen has been disposed'));
    final reason = unavailable.value;
    if (reason != null) return Future.error(StateError(reason));
    return _loading ??= _prepare();
  }

  void retryQualification() {
    if (_disposed || unavailable.value == null) return;
    unavailable.value = null;
    prepare().ignore(); // Errors are displayed through unavailable.
  }

  Future<void> _prepare() async {
    final epoch = _epoch;
    try {
      await _open();
    } catch (error) {
      if (epoch == _epoch) {
        unavailable.value = error.toString();
        await release();
      }
      rethrow;
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
    final epoch = _epoch, stops = _stops;
    await prepare();
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
      await server?.close();
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await release();
    unavailable.dispose();
  }
}
