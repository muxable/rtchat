import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/components/image/placeholder_image.dart';

// https://github.com/brianegan/transparent_image/blob/master/lib/transparent_image.dart
final kTransparentImage = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
]);

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

  PlaceholderImage get placeholderImage => PlaceholderImage(uri, scale: scale);

  const ResilientNetworkImage(this.uri, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadBuffer(
      ResilientNetworkImage key, DecoderBufferCallback decode) {
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
      DecoderBufferCallback decode) async {
    final temp = await getTemporaryDirectory();
    final cacheFile = File('${temp.path}/${key.hash}');
    final etagFile = File('${temp.path}/${key.hash}.etag');

    String? etagValue;

    Codec? decodedCache;

    if (await cacheFile.exists() && await etagFile.exists()) {
      try {
        final bytes = await cacheFile.readAsBytes();
        if (bytes.isNotEmpty) {
          decodedCache =
              await decode(await ImmutableBuffer.fromUint8List(bytes));
          etagValue = await etagFile.readAsString();
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }

    var delay = const Duration(seconds: 1);
    Object? lastError;

    for (var i = 0; i < 30; i++) {
      try {
        final request = await _httpClient.getUrl(key.uri);

        if (etagValue != null && decodedCache != null) {
          request.headers.add(HttpHeaders.ifNoneMatchHeader, etagValue);
        }

        final response = await request.close();

        if (response.statusCode != HttpStatus.ok) {
          await response.drain<List<int>>(<int>[]);

          if (response.statusCode == HttpStatus.notModified &&
              etagValue != null &&
              decodedCache != null) {
            final bytes = await cacheFile.readAsBytes();
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: bytes.lengthInBytes,
              expectedTotalBytes: bytes.lengthInBytes,
            ));
            chunkEvents.close();
            await cacheFile.setLastModified(DateTime.now());
            return decodedCache;
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
        return await decode(await ImmutableBuffer.fromUint8List(bytes));
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
