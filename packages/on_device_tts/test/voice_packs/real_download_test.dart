@Tags(['network'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:on_device_tts/on_device_tts.dart';
import 'package:path/path.dart' as p;

/// Cuts the first download off after [cutAfter] bytes, to exercise resuming
/// against the real host and its redirects.
class _CuttingClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final int cutAfter;
  var _cut = false;
  final ranges = <String?>[];

  _CuttingClient(this.cutAfter);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    ranges.add(request.headers['range']);
    final response = await _inner.send(request);
    if (_cut) return response;
    _cut = true;
    var seen = 0;
    final cut = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
      if (seen < 0) return;
      if (seen + chunk.length >= cutAfter) {
        sink.add(chunk.sublist(0, cutAfter - seen));
        sink.addError(http.ClientException('cut off by the test'));
        sink.close();
        seen = -1;
        return;
      }
      seen += chunk.length;
      sink.add(chunk);
    }));
    return http.StreamedResponse(cut, response.statusCode,
        headers: response.headers, request: request);
  }

  @override
  void close() => _inner.close();
}

/// Installs a pack from the bundled catalog for real.
///
/// `VOICE_PACK_ID` picks the pack; the Kitten pack (~31 MB) by default.
/// `VOICE_PACK_DIR` installs into that directory and keeps the pack.
void main() {
  test('installs a real voice pack, resuming an interrupted download',
      () async {
    final id =
        Platform.environment['VOICE_PACK_ID'] ?? 'kitten-nano-en-v0_8-int8';
    final keep = Platform.environment['VOICE_PACK_DIR'];
    final dir = keep != null
        ? Directory(keep)
        : await Directory.systemTemp.createTemp('voice_pack_real');
    final client = _CuttingClient(1 << 20);
    final repo = VoicePackRepository(
      directory: dir,
      client: client,
      wifiOnly: false,
      retryPolicy: const RetryPolicy(initialDelay: Duration(milliseconds: 100)),
    );
    final pack = (await repo.catalog()).pack(id)!;
    final task = repo.install(pack);
    final watch = Stopwatch()..start();
    var lastPhase = '';
    task.progress.listen((progress) {
      if (progress.phase.name != lastPhase) {
        lastPhase = progress.phase.name;
        debugPrint('${watch.elapsed} $progress');
      }
    });
    final installed = await task.done;
    debugPrint('installed ${installed.id} (${installed.sizeOnDisk} bytes) '
        'in ${watch.elapsed} at ${installed.directory}; '
        'range headers sent: ${client.ranges}');

    expect(client.ranges.first, isNull);
    expect(client.ranges[1], 'bytes=${1 << 20}-');
    for (final value in pack.config.values) {
      for (final path in (value as String).split(',')) {
        expect(FileSystemEntity.typeSync(p.join(installed.directory, path)),
            isNot(FileSystemEntityType.notFound),
            reason: path);
      }
    }
    expect(await repo.status(pack), VoicePackStatus.installed);
    if (keep == null) {
      await repo.delete(id);
      expect(Directory(installed.directory).existsSync(), isFalse);
      await dir.delete(recursive: true);
    }
    client.close();
  }, timeout: const Timeout(Duration(minutes: 20)));
}
