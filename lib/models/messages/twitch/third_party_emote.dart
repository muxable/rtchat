import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

final Map<String, Future<List<ThirdPartyEmote>>> _bttvChannelCache = {};
final Map<String, Future<List<ThirdPartyEmote>>> _ffzCache = {};
final Map<String, Future<List<ThirdPartyEmote>>> _sevenTvChannelCache = {};
Future<List<ThirdPartyEmote>>? _bttvGlobalCache;
Future<List<ThirdPartyEmote>>? _sevenTvGlobalCache;

Future<List<ThirdPartyEmote>> getBttvGlobalEmotes() async {
  final uri = Uri.parse("https://api.betterttv.net/3/cached/emotes/global");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => ThirdPartyEmote.fromBttvJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> getBttvChannelEmotes(String channelId) async {
  final uri =
      Uri.parse("https://api.betterttv.net/3/cached/users/twitch/$channelId");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return [
      ...(jsonDecode(response.body)['channelEmotes'] as List<dynamic>)
          .map((emote) => ThirdPartyEmote.fromBttvJson(emote)),
      ...(jsonDecode(response.body)['sharedEmotes'] as List<dynamic>)
          .map((emote) => ThirdPartyEmote.fromBttvJson(emote)),
    ];
  }

  return [];
}

Future<List<ThirdPartyEmote>> getFfzChannelEmotes(String channelId) async {
  final uri = Uri.parse(
      "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/$channelId");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => ThirdPartyEmote.fromFFZJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> get7tvGlobalEmotes() async {
  final uri = Uri.parse("https://api.7tv.app/v2/emotes/global");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => ThirdPartyEmote.from7tvJson(emote))
        .toList();
  }

  return [];
}

Future<List<ThirdPartyEmote>> get7tvChannelEmotes(String channelId) async {
  final uri = Uri.parse("https://api.7tv.app/v2/users/$channelId/emotes");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
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
  _bttvGlobalCache ??= getBttvGlobalEmotes();
  _sevenTvGlobalCache ??= get7tvGlobalEmotes();
  _bttvChannelCache[channelId] ??= getBttvChannelEmotes(channelId);
  _ffzCache[channelId] ??= getFfzChannelEmotes(channelId);
  _sevenTvChannelCache[channelId] ??= get7tvChannelEmotes(channelId);
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
        source: Uri.parse(json['images']['1x']));
  }

  static ThirdPartyEmote from7tvJson(Map<String, dynamic> json) {
    return ThirdPartyEmote(
      id: json['id'].toString(),
      code: json['name'],
      source: Uri.parse(json['urls'][0][1]),
    );
  }
}
