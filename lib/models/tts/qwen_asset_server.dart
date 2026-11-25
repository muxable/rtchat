import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// Serves bundled code and verified model byte ranges to a single local WebView.
class QwenAssetServer {
  QwenAssetServer._(this._server, this.pack, this.page);
  final HttpServer _server;
  final InstalledVoicePack pack;
  final Uri page;
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

  static Future<QwenAssetServer> open(InstalledVoicePack pack) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final rng = Random.secure();
    final token = base64Url.encode(List.generate(24, (_) => rng.nextInt(256)));
    final page = Uri.parse('http://127.0.0.1:${server.port}/$token/index.html');
    final assets = QwenAssetServer._(server, pack, page);
    server.listen((request) => unawaited(assets._serve(request, token)));
    return assets;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

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
        final bytes = await rootBundle.load(
          'packages/on_device_tts/assets/qwen/${path.last}',
        );
        res.contentLength = bytes.lengthInBytes;
        res.add(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
      } else if (path.length == 3 &&
          path[1] == 'model' &&
          pack.pack.files.any((f) => f.path == path.last)) {
        final file = File('${pack.directory}/${path.last}');
        if (!await file.exists()) {
          res.statusCode = HttpStatus.notFound;
          return;
        }
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
}
