import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:on_device_tts/src/voice_packs/pack_downloader.dart';

/// Stands in for the background downloader: serves [files] by URL, writing
/// them where asked.
class FakePackDownloader implements PackDownloader {
  final files = <String, Uint8List>{};

  /// Ends downloads of these URLs like this instead.
  final results = <String, PackDownloadResult>{};

  /// Ids [leftoverDownloads] returns.
  List<String> leftovers = [];
  int leftoverCalls = 0;

  final requests = <PackDownloadRequest>[];
  final cancelled = <String>[];
  final forgotten = <String>[];

  /// While set and not completed, downloads stop halfway and wait for it.
  Completer<void>? gate;

  bool _onWiFi = true;
  var _wifi = Completer<void>();
  final _running = <String, Completer<PackDownloadResult>>{};

  bool get onWiFi => _onWiFi;

  set onWiFi(bool value) {
    _onWiFi = value;
    if (value && !_wifi.isCompleted) {
      _wifi.complete();
    } else if (!value && _wifi.isCompleted) {
      _wifi = Completer();
    }
  }

  @override
  Future<List<String>> leftoverDownloads() async {
    leftoverCalls++;
    return leftovers;
  }

  @override
  Future<PackDownloadResult> download(
    PackDownloadRequest request, {
    required void Function(double fraction) onProgress,
    required void Function(PackDownloadState state) onState,
  }) {
    requests.add(request);
    final result = Completer<PackDownloadResult>();
    _running[request.id] = result;
    () async {
      onState(PackDownloadState.waiting);
      if (request.requiresWiFi && !_onWiFi) {
        await Future.any([_wifi.future, result.future]);
      }
      if (result.isCompleted) return;
      onState(PackDownloadState.running);
      final url = request.url.toString();
      final forced = results[url];
      if (forced != null) return result.complete(forced);
      final body = files[url];
      if (body == null) {
        return result.complete(const PackDownloadResult(
            PackDownloadState.notFound,
            httpStatusCode: 404));
      }
      onProgress(0.5);
      final gate = this.gate;
      if (gate != null) await Future.any([gate.future, result.future]);
      if (result.isCompleted) return;
      final file = File(request.filePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(body);
      onProgress(1);
      onState(PackDownloadState.complete);
      result.complete(const PackDownloadResult(PackDownloadState.complete));
    }();
    return result.future.whenComplete(() => _running.remove(request.id));
  }

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    final result = _running[id];
    if (result != null && !result.isCompleted) {
      result.complete(const PackDownloadResult(PackDownloadState.canceled));
    }
  }

  @override
  Future<void> forget(String id) async => forgotten.add(id);
}

String sha256Of(List<int> bytes) => sha256.convert(bytes).toString();

/// A pack of [files], path to contents, served from
/// `https://example.com/<id>-v<version>/<path>` by [serve].
VoicePack packFor(String id, Map<String, String> files, {int version = 1}) {
  return VoicePack(
    id: id,
    name: id,
    version: version,
    modelType: VoicePackModelType.supertonic,
    languages: const ['en-US'],
    speakers: const [VoicePackSpeaker(index: 0, name: 'a')],
    files: [
      for (final MapEntry(key: path, value: contents) in files.entries)
        VoicePackFile(
          url: Uri.parse('https://example.com/$id-v$version/$path'),
          size: utf8.encode(contents).length,
          sha256: sha256Of(utf8.encode(contents)),
          path: path,
        ),
    ],
  );
}
