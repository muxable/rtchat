import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:on_device_tts/on_device_tts.dart';

/// Answers requests with [handler] and records them.
class FakeClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      handler;
  final requests = <http.BaseRequest>[];

  FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return handler(request);
  }
}

/// Serves [files] by URL, honouring `Range` headers.
class FakeServer {
  final files = <String, Uint8List>{};

  /// When set, a download of a URL stops with an error after this many bytes
  /// of the response body, once per entry.
  final failAfter = <String, int>{};

  /// Responds with this status instead, for the URL.
  final statusOverride = <String, int>{};

  bool honourRange = true;

  late final client = FakeClient(_handle);

  Future<http.StreamedResponse> _handle(http.BaseRequest request) async {
    final url = request.url.toString();
    final status = statusOverride[url];
    if (status != null) {
      return http.StreamedResponse(Stream.value(utf8.encode('error')), status);
    }
    final body = files[url];
    if (body == null) {
      return http.StreamedResponse(Stream.value(utf8.encode('missing')), 404);
    }
    var start = 0;
    final range = request.headers['range'];
    if (honourRange && range != null) {
      start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
      if (start >= body.length) {
        return http.StreamedResponse(const Stream.empty(), 416);
      }
    }
    final part = body.sublist(start);
    final cut = failAfter.remove(url);
    Stream<List<int>> stream;
    if (cut != null) {
      final controller = StreamController<List<int>>();
      controller.add(part.sublist(0, cut));
      controller.addError(http.ClientException('connection reset'));
      controller.close();
      stream = controller.stream;
    } else {
      // A few chunks, to see progress.
      final chunk = (part.length / 4).ceil().clamp(1, 1 << 30);
      stream = Stream.fromIterable([
        for (var i = 0; i < part.length; i += chunk)
          part.sublist(i, (i + chunk).clamp(0, part.length)),
      ]);
    }
    return http.StreamedResponse(stream, start > 0 ? 206 : 200,
        contentLength: part.length,
        headers: start > 0
            ? {
                'content-range':
                    'bytes $start-${body.length - 1}/${body.length}'
              }
            : {});
  }
}

/// A `.tar.bz2` holding [entries]: file name to contents, or to a
/// [SymlinkTo] for a symbolic link.
Uint8List tarBz2(Map<String, Object> entries) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in entries.entries) {
    if (value is SymlinkTo) {
      archive.add(ArchiveFile.symlink(key, value.target));
    } else if (value is String) {
      archive.add(ArchiveFile.bytes(key, utf8.encode(value)));
    } else {
      archive.add(ArchiveFile.bytes(key, value as List<int>));
    }
  }
  return BZip2Encoder().encodeBytes(TarEncoder().encodeBytes(archive));
}

class SymlinkTo {
  final String target;
  const SymlinkTo(this.target);
}

String sha256Of(List<int> bytes) => sha256.convert(bytes).toString();

/// A pack of one archive served from `https://example.com/<id>.tar.bz2`.
VoicePack packFor(String id, Uint8List archive,
    {int version = 1, String? sha, String modelType = 'vits'}) {
  return VoicePack(
    id: id,
    name: id,
    version: version,
    modelTypeName: modelType,
    languages: const ['en-US'],
    speakers: const [VoicePackSpeaker(index: 0, name: 'a')],
    files: [
      VoicePackFile(
        url: Uri.parse('https://example.com/$id-v$version.tar.bz2'),
        size: archive.length,
        sha256: sha ?? sha256Of(archive),
        path: '',
        archive: VoicePackArchiveType.tarBz2,
        stripComponents: 1,
      ),
    ],
  );
}

String catalogJson(int version, List<VoicePack> packs) =>
    jsonEncode(VoicePackCatalog(version: version, allPacks: packs).toJson());
