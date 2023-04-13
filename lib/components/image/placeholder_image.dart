import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;

import 'package:path_provider/path_provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';

class PlaceholderImage extends ImageProvider<PlaceholderImage> {
  final Uri uri;
  final double scale;

  String get hash =>
      sha1.convert(convert.utf8.encode(uri.toString())).toString();

  const PlaceholderImage(this.uri, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadBuffer(
      PlaceholderImage key, DecoderBufferCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      chunkEvents: chunkEvents.stream,
      codec: _loadAsync(key, chunkEvents, decode),
      scale: scale,
      debugLabel: key.uri.toString(),
      informationCollector: _imageStreamInformationCollector(key),
    );
  }

  InformationCollector? _imageStreamInformationCollector(PlaceholderImage key) {
    InformationCollector? collector;
    assert(() {
      collector = () => <DiagnosticsNode>[
            DiagnosticsProperty<ImageProvider>('Image provider', this),
            DiagnosticsProperty<PlaceholderImage>('Image key', key),
          ];
      return true;
    }());
    return collector;
  }

  static Future<Codec> _loadAsync(
      PlaceholderImage key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderBufferCallback decode) async {
    final temp = await getTemporaryDirectory();
    final cacheFile = File('${temp.path}/${key.hash}');
    final etagFile = File('${temp.path}/${key.hash}.etag');

    Codec? decodedCache;

    if (await cacheFile.exists() && await etagFile.exists()) {
      try {
        final bytes = await cacheFile.readAsBytes();
        if (bytes.isNotEmpty) {
          decodedCache =
              await decode(await ImmutableBuffer.fromUint8List(bytes));
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: bytes.lengthInBytes,
            expectedTotalBytes: bytes.lengthInBytes,
          ));
          chunkEvents.close();
          return decodedCache;
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
    }
    return await decode(await ImmutableBuffer.fromUint8List(kTransparentImage));
  }

  @override
  Future<PlaceholderImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is PlaceholderImage &&
        other.uri == uri &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(uri, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'PlaceholderImage')}("$uri", scale: $scale)';
}
