import 'dart:convert';
import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

final Map<String, Future<List<Emote>>> _bttvChannelCache = {};
final Map<String, Future<List<Emote>>> _ffzCache = {};
final Map<String, Future<List<Emote>>> _sevenTvChannelCache = {};
Future<List<Emote>>? _bttvGlobalCache;
Future<List<Emote>>? _sevenTvGlobalCache;

final getUserEmotes = FirebaseFunctions.instance.httpsCallable("getUserEmotes");

Future<List<Emote>> getBttvGlobalEmotes() async {
  final uri = Uri.parse("https://api.betterttv.net/3/cached/emotes/global");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => Emote.fromBttvJson(emote))
        .toList();
  }

  return [];
}

Future<List<Emote>> getBttvChannelEmotes(String channelId) async {
  final uri =
      Uri.parse("https://api.betterttv.net/3/cached/users/twitch/$channelId");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return [
      ...(jsonDecode(response.body)['channelEmotes'] as List<dynamic>)
          .map((emote) => Emote.fromBttvJson(emote)),
      ...(jsonDecode(response.body)['sharedEmotes'] as List<dynamic>)
          .map((emote) => Emote.fromBttvJson(emote)),
    ];
  }

  return [];
}

Future<List<Emote>> getFfzChannelEmotes(String channelId) async {
  final uri = Uri.parse(
      "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/$channelId");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => Emote.fromFFZJson(emote))
        .toList();
  }

  return [];
}

Future<List<Emote>> get7tvGlobalEmotes() async {
  final uri = Uri.parse("https://api.7tv.app/v2/emotes/global");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => Emote.from7tvJson(emote))
        .toList();
  }

  return [];
}

Future<List<Emote>> get7tvChannelEmotes(String channelId) async {
  final uri = Uri.parse("https://api.7tv.app/v2/users/$channelId/emotes");
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return (jsonDecode(response.body) as List<dynamic>)
        .map((emote) => Emote.from7tvJson(emote))
        .toList();
  }

  return [];
}

Future<List<Emote>> getTwitchEmotes(String channelId) async {
  final response = await getUserEmotes({
    "provider": "twitch",
    "channelId": channelId,
  });

  final emoteList = response.data['emotes'] as List;

  return emoteList
      .map((individualEmote) => Emote.fromTwitchJson(individualEmote))
      .toList();
}

Future<List<Emote>> getThirdPartyEmotes(
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

class Emote {
  final String id;
  final String code;
  final Uri source;

  Emote({required this.id, required this.code, required this.source});

  static Emote fromBttvJson(Map<String, dynamic> json) {
    return Emote(
        id: json['id'],
        code: json['code'],
        source: Uri.parse('https://cdn.betterttv.net/emote/${json['id']}/1x'));
  }

  static Emote fromFFZJson(Map<String, dynamic> json) {
    return Emote(
        id: json['id'].toString(),
        code: json['code'],
        source: Uri.parse(json['images']['1x']));
  }

  static Emote from7tvJson(Map<String, dynamic> json) {
    return Emote(
      id: json['id'].toString(),
      code: json['name'],
      source: Uri.parse(json['urls'][0][1]),
    );
  }

  static Emote fromTwitchJson(dynamic json) {
    return Emote(
      id: json['id'].toString(),
      code: json['code'],
      source: Uri.parse(json['source']),
    );
  }
}
