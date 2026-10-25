import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io';
import 'dart:ui';

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

/// 64-bit FNV-1a hash of [input], as 16 hex digits. Used as a stable cache
/// filename for a URL.
String fnv1a64(String input) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(input)) {
    hash ^= byte;
    hash *= 0x100000001b3;
  }
  return (hash >>> 32).toRadixString(16).padLeft(8, '0') +
      (hash & 0xffffffff).toRadixString(16).padLeft(8, '0');
}

class ResilientNetworkImage extends ImageProvider<ResilientNetworkImage> {
  static final HttpClient _sharedHttpClient =
      HttpClient()..autoUncompress = false;

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

  /// How long a disk-cached image is served without revalidating it.
  static const freshness = Duration(days: 1);

  static Future<Directory>? _cacheDirectory;

  static Future<Directory> get cacheDirectory =>
      _cacheDirectory ??= getTemporaryDirectory().catchError((
        Object e,
        StackTrace stack,
      ) {
        _cacheDirectory = null;
        Error.throwWithStackTrace(e, stack);
      });

  /// The cached bytes for [uri]. Its validators live in a `.meta` sidecar.
  static Future<File> cacheFileFor(Uri uri) async =>
      File('${(await cacheDirectory).path}/${fnv1a64(uri.toString())}');

  // In-flight downloads, shared by concurrent loads. Only bytes are shared:
  // each completer owns and disposes its own codec.
  static final Map<String, Future<(Uint8List, HttpHeaders)>> _pending = {};
  static final Map<String, Future<void>> _revalidating = {};
  static int _tempCounter = 0;

  /// Completes once all in-flight background revalidations finish.
  @visibleForTesting
  static Future<void> debugRevalidations() =>
      Future.wait(_revalidating.values.toList());

  final Uri uri;
  final double scale;

  String get hash => fnv1a64(uri.toString());

  PlaceholderImage get placeholderImage => PlaceholderImage(uri, scale: scale);

  const ResilientNetworkImage(this.uri, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(
    ResilientNetworkImage key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key, chunkEvents, decode),
      scale: scale,
      debugLabel: key.uri.toString(),
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  InformationCollector? _imageStreamInformationCollector(
    ResilientNetworkImage key,
  ) {
    InformationCollector? collector;
    assert(() {
      collector =
          () => <DiagnosticsNode>[
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
    ImageDecoderCallback decode,
  ) async {
    try {
      final hash = key.hash;
      final cacheFile = await cacheFileFor(key.uri);
      final metaFile = File('${cacheFile.path}.meta');

      // Serve a disk hit immediately and revalidate it in the background once
      // it goes stale.
      try {
        final stat = await cacheFile.stat();
        if (stat.type == FileSystemEntityType.file) {
          final bytes = await cacheFile.readAsBytes();
          if (bytes.isNotEmpty) {
            final Codec codec;
            try {
              codec = await decode(await ImmutableBuffer.fromUint8List(bytes));
            } catch (_) {
              // Undecodable entry, drop it and refetch.
              await _deleteCache(cacheFile, metaFile);
              rethrow;
            }
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: bytes.lengthInBytes,
                expectedTotalBytes: bytes.lengthInBytes,
              ),
            );
            if (DateTime.now().difference(stat.modified) > freshness) {
              _revalidating[hash] ??= _revalidate(
                key.uri,
                cacheFile,
                metaFile,
              ).whenComplete(() {
                _revalidating.remove(hash);
              });
            }
            return codec;
          }
        }
      } catch (e) {
        // Unreadable or undecodable cache entry, fall back to the network.
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }

      final pending = _pending[hash];
      final fetch =
          pending ??
          (_pending[hash] = _fetch(key.uri, chunkEvents).whenComplete(() {
            // A block body: returning the removed future would deadlock.
            _pending.remove(hash);
          }));
      final (bytes, headers) = await fetch;
      // Decode errors are not retried, and undecodable bytes aren't cached.
      final codec = await decode(await ImmutableBuffer.fromUint8List(bytes));
      if (pending == null) {
        await _writeCache(cacheFile, metaFile, bytes, headers);
      }
      return codec;
    } on NetworkImageLoadException {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  /// Downloads [uri], retrying everything but 4xx responses.
  static Future<(Uint8List, HttpHeaders)> _fetch(
    Uri uri,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    var delay = const Duration(seconds: 1);
    Object? lastError;

    for (var i = 0; i < 30; i++) {
      try {
        final request = await _httpClient.getUrl(uri);
        final response = await request.close();

        if (response.statusCode != HttpStatus.ok) {
          await response.drain<List<int>>(<int>[]);
          if (response.statusCode >= 400 && response.statusCode < 500) {
            throw NetworkImageLoadException(
              statusCode: response.statusCode,
              uri: uri,
            );
          } else {
            // assume this is a retriable error.
            continue;
          }
        }

        final bytes = await consolidateHttpClientResponseBytes(
          response,
          onBytesReceived: (int cumulative, int? total) {
            if (chunkEvents.isClosed) return;
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: cumulative,
                expectedTotalBytes: total,
              ),
            );
          },
        );

        if (bytes.lengthInBytes == 0) {
          throw Exception('ResilientNetworkImage is an empty file: $uri');
        }

        return (bytes, response.headers);
      } on NetworkImageLoadException {
        rethrow;
      } catch (e) {
        // retry this error
        await Future.delayed(delay);
        delay = Duration(milliseconds: (1.5 * delay.inMilliseconds).toInt());
        lastError = e;
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    throw Exception('Failed to fetch ResilientNetworkImage');
  }

  /// Conditionally refetches a stale cache entry. Failures are logged and
  /// otherwise ignored; the entry stays stale and is retried on a later load.
  static Future<void> _revalidate(
    Uri uri,
    File cacheFile,
    File metaFile,
  ) async {
    try {
      final request = await _httpClient.getUrl(uri);
      try {
        final meta = jsonDecode(await metaFile.readAsString());
        final etag = meta['etag'];
        final lastModified = meta['lastModified'];
        if (etag is String) {
          request.headers.add(HttpHeaders.ifNoneMatchHeader, etag);
        }
        if (lastModified is String) {
          request.headers.add(HttpHeaders.ifModifiedSinceHeader, lastModified);
        }
      } catch (_) {
        // No validators, fall back to an unconditional refetch.
      }
      final response = await request.close();
      if (response.statusCode == HttpStatus.notModified) {
        await response.drain<List<int>>(<int>[]);
        await cacheFile.setLastModified(DateTime.now());
      } else if (response.statusCode == HttpStatus.ok) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        if (bytes.isNotEmpty) {
          // Don't replace a good entry with something undecodable.
          (await instantiateImageCodec(bytes)).dispose();
          await _writeCache(cacheFile, metaFile, bytes, response.headers);
        }
      } else {
        await response.drain<List<int>>(<int>[]);
        if (response.statusCode == HttpStatus.notFound ||
            response.statusCode == HttpStatus.gone) {
          // The image is gone, so the next load errors like a cold miss.
          await _deleteCache(cacheFile, metaFile);
        }
      }
    } catch (e) {
      debugPrint('ResilientNetworkImage revalidation failed: $uri: $e');
    }
  }

  /// Writes the bytes and validators through temp files and renames, so a
  /// concurrent reader never sees a partial file.
  static Future<void> _writeCache(
    File cacheFile,
    File metaFile,
    Uint8List bytes,
    HttpHeaders headers,
  ) async {
    final suffix =
        '${DateTime.now().microsecondsSinceEpoch}-${_tempCounter++}.tmp';
    final tmpMeta = File('${metaFile.path}.$suffix');
    final tmpBytes = File('${cacheFile.path}.$suffix');
    try {
      final meta = {
        if (headers[HttpHeaders.etagHeader]?.first case final etag?)
          'etag': etag,
        if (headers[HttpHeaders.lastModifiedHeader]?.first case final lm?)
          'lastModified': lm,
      };
      await tmpMeta.writeAsString(jsonEncode(meta));
      await tmpBytes.writeAsBytes(bytes);
      // Bytes first: a new body with old validators only costs a refetch.
      await tmpBytes.rename(cacheFile.path);
      await tmpMeta.rename(metaFile.path);
    } catch (e) {
      debugPrint('ResilientNetworkImage cache write failed: $e');
      await _deleteCache(tmpBytes, tmpMeta);
    }
  }

  static Future<void> _deleteCache(File cacheFile, File metaFile) async {
    for (final file in [cacheFile, metaFile]) {
      try {
        await file.delete();
      } catch (_) {
        // Already gone.
      }
    }
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
