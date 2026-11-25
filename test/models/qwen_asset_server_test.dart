import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/models/tts/qwen_asset_server.dart';

class _LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'the WebView receives UTF-8 asset bytes and exact model ranges',
    () async {
      final dir = await Directory.systemTemp.createTemp('qwen-assets-');
      addTearDown(() => dir.delete(recursive: true));
      final pack = bundledVoicePacks.singleWhere(
        (p) => p.modelType == VoicePackModelType.qwen3Tts,
      );
      await File(
        '${dir.path}/talker_cache.onnx',
      ).writeAsBytes(List.generate(32, (i) => i));
      final server = await QwenAssetServer.open(
        InstalledVoicePack(
          pack: pack,
          directory: dir.path,
          sizeOnDisk: 32,
          installedAt: DateTime(2024),
        ),
      );
      addTearDown(server.close);
      final client = _LocalHttp().createHttpClient(null);
      addTearDown(() => client.close(force: true));
      final script =
          await (await client.getUrl(
            server.page.resolve('decoder.mjs'),
          )).close();
      final body = await utf8.decoder.bind(script).join();
      expect(script.statusCode, 200);
      expect(
        body,
        await rootBundle.loadString(
          'packages/on_device_tts/assets/qwen/decoder.mjs',
        ),
      );
      final req = await client.getUrl(
        server.page.resolve('model/talker_cache.onnx'),
      );
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=7-11');
      final range = await req.close();
      expect(range.statusCode, 206);
      expect(
        range.headers.value(HttpHeaders.contentRangeHeader),
        'bytes 7-11/32',
      );
      expect(await range.expand((bytes) => bytes).toList(), [7, 8, 9, 10, 11]);
      final missing =
          await (await client.getUrl(
            server.page.resolve('model/code_predictor.onnx'),
          )).close();
      expect(missing.statusCode, 404);
      await missing.drain<void>();
    },
  );
}
