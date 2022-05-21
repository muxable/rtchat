import 'dart:convert' as convert;
import 'dart:io';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ResilientNetworkImage extends ImageProvider<ResilientNetworkImage> {
  static final _client = HttpClient();
  static final Map<String, Future<Codec>> _pending = {};

  final Uri uri;
  final double scale;

  const ResilientNetworkImage(this.uri, {this.scale = 1.0});

  @override
  ImageStreamCompleter load(ResilientNetworkImage key, DecoderCallback decode) {
    final hash =
        sha1.convert(convert.utf8.encode(key.uri.toString())).toString();
    return MultiFrameImageStreamCompleter(
        codec: _pending[hash] ??= _loadAsync(hash, key.uri, decode),
        scale: scale);
  }

  static Future<Codec> _loadAsync(
      String hash, Uri uri, DecoderCallback decode) async {
    final temp = await getTemporaryDirectory();
    final cacheFile = File('$temp/$hash');
    final etagFile = File('$temp/$hash.etag');

    String? etagValue;

    if (await cacheFile.exists() && await etagFile.exists()) {
      etagValue = await etagFile.readAsString();
    }

    while (true) {
      try {
        final request =
            await _client.getUrl(uri).timeout(const Duration(seconds: 30));

        if (etagValue != null) {
          request.headers.add(HttpHeaders.ifNoneMatchHeader, etagValue);
        }

        final response =
            await request.close().timeout(const Duration(seconds: 30));

        if (response.statusCode == 302 && etagValue != null) {
          return await decode(await cacheFile.readAsBytes());
        }
        if (response.statusCode != 200) {
          throw Exception('Failed to load image: ${response.statusCode}');
        }

        final builder = await response.fold<BytesBuilder>(
          BytesBuilder(),
          (buffer, bytes) => buffer..add(bytes),
        );

        final bytes = builder.takeBytes();

        if (bytes.lengthInBytes == 0) {
          throw Exception('Failed to load image: empty response');
        }

        final etagHeader = response.headers[HttpHeaders.etagHeader]?.first;
        if (etagHeader != null) {
          await cacheFile.writeAsBytes(bytes);
          await etagFile.writeAsString(etagHeader);
        }

        return await decode(bytes);
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  Future<ResilientNetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }
}
