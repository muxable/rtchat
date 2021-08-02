import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/models/channels.dart';

final Map<String, Future<Map<String, ThirdPartyEmote>>> _bttvChannelCache = {};
final Map<String, Future<Map<String, ThirdPartyEmote>>> _ffzCache = {};
Future<Map<String, ThirdPartyEmote>>? _globalCache;

Future<Map<String, ThirdPartyEmote>> getGlobalEmotes(Uri uri) async {
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

Future<Map<String, ThirdPartyEmote>> getChannelEmotes(Uri uri) async {
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

class ThirdPartyEmoteModel extends ChangeNotifier {
  final Map<String, ThirdPartyEmote> _channelFFZEmotes = {};
  final Map<String, ThirdPartyEmote> _channelBttvEmotes = {};
  final Map<String, ThirdPartyEmote> _globalBttvEmotes = {};

  Future<void> subscribe(Set<Channel> channels) async {
    _channelBttvEmotes.clear();
    _globalBttvEmotes.clear();
    if (_globalCache == null) {
      final uri = Uri.parse("https://api.betterttv.net/3/cached/emotes/global");
      _globalCache = getGlobalEmotes(uri);
    }
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      if (!_bttvChannelCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.betterttv.net/3/cached/users/twitch/${channel.channelId}");
        _bttvChannelCache[channel.channelId] = getChannelEmotes(uri);
      }
      if (!_ffzCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.betterttv.net/3/cached/frankerfacez/users/twitch/${channel.channelId}");
        _ffzCache[channel.channelId] = getFFZEmotes(uri);
      }
    }
    _globalBttvEmotes.addAll((await _globalCache)!);
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      _channelBttvEmotes.addAll((await _bttvChannelCache[channel.channelId])!);
      _channelFFZEmotes.addAll((await _ffzCache[channel.channelId])!);
    }

    notifyListeners();
  }

  String? Function(String) get resolver =>
      (String text) => (_globalBttvEmotes[text] ??
              _channelBttvEmotes[text] ??
              _channelFFZEmotes[text])
          ?.source;
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
}
