import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ResilientNetworkImage extends ImageProvider<ResilientNetworkImage> {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false;

  static HttpClient get _httpClient {
    HttpClient client = _sharedHttpClient;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client;
  }

  static final Map<String, Future<Codec>> _pending = {};

  final Uri uri;
  final double scale;

  String get hash =>
      sha1.convert(convert.utf8.encode(uri.toString())).toString();

  const ResilientNetworkImage(this.uri, {this.scale = 1.0});

  @override
  ImageStreamCompleter load(ResilientNetworkImage key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _pending[hash] ??= _loadAsync(key, chunkEvents, decode).then((x) {
        _pending.remove(hash);
        return x;
      }),
      scale: scale,
      debugLabel: key.uri.toString(),
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  InformationCollector? _imageStreamInformationCollector(
      ResilientNetworkImage key) {
    InformationCollector? collector;
    assert(() {
      collector = () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<ResilientNetworkImage>('Image key', key),
          ];
      return true;
    }());
    return collector;
  }

  static Future<Codec> _loadAsync(
      ResilientNetworkImage key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderCallback decode) async {
    final temp = await getTemporaryDirectory();
    final cacheFile = File('${temp.path}/${key.hash}');
    final etagFile = File('${temp.path}/${key.hash}.etag');

    String? etagValue;

    if (await cacheFile.exists() && await etagFile.exists()) {
      etagValue = await etagFile.readAsString();
    }

    var delay = const Duration(seconds: 1);
    Object? lastError;

    for (var i = 0; i < 30; i++) {
      try {
        final request = await _httpClient.getUrl(key.uri);

        if (etagValue != null) {
          request.headers.add(HttpHeaders.ifNoneMatchHeader, etagValue);
        }

        final response = await request.close();

        if (response.statusCode != HttpStatus.ok) {
          await response.drain<List<int>>(<int>[]);

          if (response.statusCode == HttpStatus.notModified &&
              etagValue != null) {
            final bytes = await cacheFile.readAsBytes();
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: bytes.lengthInBytes,
              expectedTotalBytes: bytes.lengthInBytes,
            ));
            chunkEvents.close();
            return decode(bytes);
          }
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw NetworkImageLoadException(
                statusCode: response.statusCode, uri: key.uri);
          } else {
            // assume this is a retriable error.
            continue;
          }
        }

        final bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (int cumulative, int? total) {
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ));
          },
        );

        if (bytes.lengthInBytes == 0) {
          throw Exception('ResilientNetworkImage is an empty file: ${key.uri}');
        }

        final etagHeader = response.headers[HttpHeaders.etagHeader]?.first;
        if (etagHeader != null) {
          await cacheFile.writeAsBytes(bytes);
          await etagFile.writeAsString(etagHeader);
        }

        chunkEvents.close();
        return decode(bytes);
      } on NetworkImageLoadException {
        chunkEvents.close();
        scheduleMicrotask(() {
          PaintingBinding.instance.imageCache.evict(key);
        });
        rethrow;
      } catch (e) {
        // retry this error
        await Future.delayed(delay);
        delay = Duration(milliseconds: (1.5 * delay.inMilliseconds).toInt());
        lastError = e;
      }
    }
    chunkEvents.close();
    if (lastError != null) {
      throw lastError;
    }
    throw Exception('Failed to fetch ResilientNetworkImage');
  }

  @override
  Future<ResilientNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ResilientNetworkImage &&
        other.uri == uri &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(uri, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'ResilientNetworkImage')}("$uri", scale: $scale)';
}
