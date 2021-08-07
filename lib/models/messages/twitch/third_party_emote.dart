import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/models/channels.dart';

final Map<String, Future<Map<String, ThirdPartyEmote>>> _bttvChannelCache = {};
final Map<String, Future<Map<String, ThirdPartyEmote>>> _ffzCache = {};
final Map<String, Future<Map<String, ThirdPartyEmote>>> _sevenTvChannelCache =
    {};
Future<Map<String, ThirdPartyEmote>>? _bttvGlobalCache;
Future<Map<String, ThirdPartyEmote>>? _sevenTvGlobalCache;

Future<Map<String, ThirdPartyEmote>> getBttvGlobalEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, ThirdPartyEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body).forEach((emote) {
      final parsedEmote = ThirdPartyEmote.fromBttvJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

Future<Map<String, ThirdPartyEmote>> getBttvChannelEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, ThirdPartyEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body)['channelEmotes'].forEach((emote) {
      final parsedEmote = ThirdPartyEmote.fromBttvJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });

    jsonDecode(response.body)['sharedEmotes'].forEach((emote) {
      final parsedEmote = ThirdPartyEmote.fromBttvJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

Future<Map<String, ThirdPartyEmote>> getFFZEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, ThirdPartyEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body).forEach((emote) {
      final parsedEmote = ThirdPartyEmote.fromFFZJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

Future<Map<String, ThirdPartyEmote>> get7tvEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, ThirdPartyEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body).forEach((emote) {
      final parsedEmote = ThirdPartyEmote.from7tvJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

class ThirdPartyEmoteModel extends ChangeNotifier {
  final Map<String, ThirdPartyEmote> _emotes = {};

  Future<void> subscribe(Set<Channel> channels) async {
    _emotes.clear();
    if (_bttvGlobalCache == null) {
      final uri = Uri.parse("https://api.betterttv.net/3/cached/emotes/global");
      _bttvGlobalCache = getBttvGlobalEmotes(uri);
    }
    if (_sevenTvGlobalCache == null) {
      final uri = Uri.parse("https://api.7tv.app/v2/emotes/global");
      _sevenTvGlobalCache = get7tvEmotes(uri);
    }
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      if (!_bttvChannelCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.betterttv.net/3/cached/users/twitch/${channel.channelId}");
        _bttvChannelCache[channel.channelId] = getBttvChannelEmotes(uri);
      }
      if (!_ffzCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/${channel.channelId}");
        _ffzCache[channel.channelId] = getFFZEmotes(uri);
      }
      if (!_sevenTvChannelCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.7tv.app/v2/users/${channel.channelId}/emotes");
        _sevenTvChannelCache[channel.channelId] = get7tvEmotes(uri);
      }
    }
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      _emotes.addAll((await _sevenTvChannelCache[channel.channelId])!);
      _emotes.addAll((await _ffzCache[channel.channelId])!);
      _emotes.addAll((await _bttvChannelCache[channel.channelId])!);
    }
    _emotes.addAll((await _sevenTvGlobalCache)!);
    _emotes.addAll((await _bttvGlobalCache)!);

    notifyListeners();
  }

  String? Function(String) get resolver => (text) => _emotes[text]?.source;
}

class ThirdPartyEmote {
  final String id;
  final String code;
  final String source;

  ThirdPartyEmote({required this.id, required this.code, required this.source});

  static ThirdPartyEmote fromBttvJson(Map<String, dynamic> json) {
    return ThirdPartyEmote(
        id: json['id'],
        code: json['code'],
        source: 'https://cdn.betterttv.net/emote/${json['id']}/1x');
  }

  static ThirdPartyEmote fromFFZJson(Map<String, dynamic> json) {
    return ThirdPartyEmote(
        id: json['id'].toString(),
        code: json['code'],
        source: json['images']['1x']);
  }

  static ThirdPartyEmote from7tvJson(Map<String, dynamic> json) {
    return ThirdPartyEmote(
      id: json['id'].toString(),
      code: json['name'],
      source: json['urls'][0][1],
    );
  }
}
