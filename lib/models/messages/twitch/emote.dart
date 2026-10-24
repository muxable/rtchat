import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';

/// How long to wait before fetching the emotes again after a failure.
@visibleForTesting
var emoteRetryDelay = const Duration(seconds: 1);

/// Reports emotes that couldn't be fetched, to Crashlytics by default.
@visibleForTesting
void Function(Object error, StackTrace stack) reportEmoteError =
    FirebaseCrashlytics.instance.recordError;

/// The emotes usable in [channel]. Twitch's include those of the user [api]
/// calls as. If they can't be fetched, e.g. the backend is briefly
/// unavailable, they come from an outdated cache, or there are none.
Future<List<Emote>> getEmotes(Channel channel, Api api) async {
  final temp = await getTemporaryDirectory();
  final cacheFile = File('${temp.path}/emotes/${channel.toString()}.json');
  List<Emote>? cached;
  try {
    if (await cacheFile.exists()) {
      final stats = await cacheFile.stat();
      final json = await cacheFile.readAsString();
      cached =
          (jsonDecode(json) as List).map((e) => Emote.fromJson(e)).toList();
      if (stats.modified.isAfter(
        DateTime.now().subtract(const Duration(days: 1)),
      )) {
        return cached;
      }
    }
  } catch (_) {
    // a cache cut short, e.g. when the disk filled up while it was written,
    // is fetched again.
    await _deleteCache(cacheFile);
  }

  final dynamic data;
  final List<Emote> emotes;
  try {
    data = await _fetchEmotes(channel, api);
    emotes = (data as List).map(Emote.fromJson).toList();
  } catch (e, st) {
    reportEmoteError(e, st);
    return cached ?? [];
  }
  try {
    await cacheFile.create(recursive: true);
    await cacheFile.writeAsString(jsonEncode(data));
  } catch (_) {
    // the emotes are still usable without the cache.
    await _deleteCache(cacheFile);
  }
  return emotes;
}

/// The emotes' JSON from the backend, retried as it can be briefly
/// unavailable.
Future<dynamic> _fetchEmotes(Channel channel, Api api) async {
  for (var attempt = 1; ; attempt++) {
    try {
      final response = await api.callable("getEmotes")({
        "provider": channel.provider,
        "channelId": channel.channelId,
      });
      return response.data;
    } catch (_) {
      if (attempt == 3) rethrow;
      await Future.delayed(emoteRetryDelay);
    }
  }
}

Future<void> _deleteCache(File cacheFile) async {
  try {
    await cacheFile.delete();
  } catch (_) {
    // there was nothing to delete.
  }
}

class Emote {
  final String provider;
  final String? category;
  final String id;
  final String code;
  final String imageUrl;

  Emote({
    required this.provider,
    required this.category,
    required this.id,
    required this.code,
    required this.imageUrl,
  });

  Uri get uri =>
      Uri.parse(imageUrl.startsWith("//") ? "https:$imageUrl" : imageUrl);

  ResilientNetworkImage get image => ResilientNetworkImage(uri);

  static Emote fromJson(dynamic json) {
    return Emote(
      provider: json['provider'] as String,
      category: json['category'] as String?,
      id: json['id'].toString(),
      code: json['code'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}
