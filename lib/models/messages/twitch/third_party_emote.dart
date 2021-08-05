import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

final Map<String, Future<List<ThirdPartyEmote>>> _bttvChannelCache = {};
final Map<String, Future<List<ThirdPartyEmote>>> _ffzCache = {};
final Map<String, Future<List<ThirdPartyEmote>>> _sevenTvChannelCache = {};
Future<List<ThirdPartyEmote>>? _bttvGlobalCache;
Future<List<ThirdPartyEmote>>? _sevenTvGlobalCache;

Future<List<ThirdPartyEmote>> getBttvGlobalEmotes(Uri uri) async {
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)
        .map((emote) => ThirdPartyEmote.fromBttvJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> getBttvChannelEmotes(Uri uri) async {
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return [
      ...jsonDecode(response.body)['channelEmotes']
          .map((emote) => ThirdPartyEmote.fromBttvJson(emote)),
      ...jsonDecode(response.body)['sharedEmotes']
          .map((emote) => ThirdPartyEmote.fromBttvJson(emote)),
    ];
  }

  return [];
}

Future<List<ThirdPartyEmote>> getFFZEmotes(Uri uri) async {
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)
        .map((emote) => ThirdPartyEmote.fromFFZJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> get7tvEmotes(Uri uri) async {
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return jsonDecode(response.body)
        .map((emote) => ThirdPartyEmote.from7tvJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> getThirdPartyEmotes(
    String provider, String channelId) async {
  if (provider != "twitch") {
    return [];
  }
  if (_bttvGlobalCache == null) {
    final uri = Uri.parse("https://api.betterttv.net/3/cached/emotes/global");
    _bttvGlobalCache = getBttvGlobalEmotes(uri);
  }
  if (_sevenTvGlobalCache == null) {
    final uri = Uri.parse("https://api.7tv.app/v2/emotes/global");
    _sevenTvGlobalCache = get7tvEmotes(uri);
  }
  if (!_bttvChannelCache.containsKey(channelId)) {
    final uri =
        Uri.parse("https://api.betterttv.net/3/cached/users/twitch/$channelId");
    _bttvChannelCache[channelId] = getBttvChannelEmotes(uri);
  }
  if (!_ffzCache.containsKey(channelId)) {
    final uri = Uri.parse(
        "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/$channelId");
    _ffzCache[channelId] = getFFZEmotes(uri);
  }
  if (!_sevenTvChannelCache.containsKey(channelId)) {
    final uri = Uri.parse("https://api.7tv.app/v2/users/$channelId/emotes");
    _sevenTvChannelCache[channelId] = get7tvEmotes(uri);
  }
  return [
    ...(await _sevenTvChannelCache[channelId]!),
    ...(await _ffzCache[channelId]!),
    ...(await _bttvChannelCache[channelId]!),
    ...(await _sevenTvGlobalCache!),
    ...(await _bttvGlobalCache!)
  ];
}

class ThirdPartyEmote {
  final String id;
  final String code;
  final Uri source;

  ThirdPartyEmote({required this.id, required this.code, required this.source});

  static ThirdPartyEmote fromBttvJson(Map<String, dynamic> json) {
    return ThirdPartyEmote(
        id: json['id'],
        code: json['code'],
        source: Uri.parse('https://cdn.betterttv.net/emote/${json['id']}/1x'));
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
