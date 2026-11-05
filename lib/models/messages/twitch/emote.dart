import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/models/channels.dart';

/// How long to wait before fetching the emotes again after a failure.
@visibleForTesting
var emoteRetryDelay = const Duration(seconds: 1);

/// Reports emotes that couldn't be fetched, to Crashlytics by default.
@visibleForTesting
void Function(Object error, StackTrace stack) reportEmoteError =
    _recordToCrashlytics;

void _recordToCrashlytics(Object error, StackTrace stack) =>
    FirebaseCrashlytics.instance.recordError(error, stack);

/// The user [api] calls as, as the emotes usable depend on who's signed in.
@visibleForTesting
String Function(Api api) emoteCaller = _signedInUid;

String _signedInUid(Api api) =>
    FirebaseAuth.instanceFor(app: api.app).currentUser?.uid ?? 'anon';

/// The emotes usable in [channel]. Twitch's include those of the user [api]
/// calls as. If they can't be fetched, e.g. the backend is briefly
/// unavailable, they come from an outdated cache, or there are none.
///
/// Concurrent requests for the same channel as the same user, e.g. from the
/// chat and the message input opening it together, share one fetch so they
/// don't write the cache at the same time. Emotes fetched after the user
/// changes aren't theirs, so they're neither cached nor returned.
Future<List<Emote>> getEmotes(Channel channel, Api api) {
  final caller = emoteCaller(api);
  final key = '$caller/$channel';
  return _inFlight[key] ??= _getEmotes(channel, api, caller, key).whenComplete(
    () {
      _inFlight.remove(key);
    },
  );
}

final _inFlight = <String, Future<List<Emote>>>{};

Future<List<Emote>> _getEmotes(
  Channel channel,
  Api api,
  String caller,
  String key,
) async {
  final temp = await getTemporaryDirectory();
  final cacheFile = File('${temp.path}/emotes/$key.json');
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
    data = await _fetchEmotes(channel, api, caller);
    emotes = (data as List).map(Emote.fromJson).toList();
  } on _CallerChanged {
    return cached ?? [];
  } catch (e, st) {
    reportEmoteError(e, st);
    return cached ?? [];
  }
  if (emoteCaller(api) != caller) {
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

/// The emotes' JSON from the backend as [caller], retried as it can be
/// briefly unavailable. Throws [_CallerChanged] if the user [api] calls as
/// is no longer [caller].
Future<dynamic> _fetchEmotes(Channel channel, Api api, String caller) async {
  for (var attempt = 1; ; attempt++) {
    if (emoteCaller(api) != caller) {
      throw _CallerChanged();
    }
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

class _CallerChanged implements Exception {}

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

  CachedNetworkImageProvider get image =>
      CachedNetworkImageProvider(uri.toString());

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
