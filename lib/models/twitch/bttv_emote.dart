import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/models/channels.dart';

final Map<String, Future<Map<String, BttvEmote>>> _localCache = {};
Future<Map<String, BttvEmote>>? _globalCache;

Future<Map<String, BttvEmote>> getGlobalEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, BttvEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body).forEach((emote) {
      final parsedEmote = BttvEmote.fromJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

Future<Map<String, BttvEmote>> getChannelEmotes(Uri uri) async {
  final response = await http.get(uri);
  Map<String, BttvEmote> result = {};

  if (response.statusCode == 200) {
    jsonDecode(response.body)['channelEmotes'].forEach((emote) {
      final parsedEmote = BttvEmote.fromJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });

    jsonDecode(response.body)['sharedEmotes'].forEach((emote) {
      final parsedEmote = BttvEmote.fromJson(emote);
      result[parsedEmote.code] = parsedEmote;
    });
  }

  return result;
}

class BttvEmoteModel extends ChangeNotifier {
  final Map<String, BttvEmote> _channelBttvEmotes = {};
  final Map<String, BttvEmote> _globalBttvEmotes = {};

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
      if (!_localCache.containsKey(channel.channelId)) {
        final uri = Uri.parse(
            "https://api.betterttv.net/3/cached/users/twitch/${channel.channelId}");
        _localCache[channel.channelId] = getChannelEmotes(uri);
      }
    }
    _globalBttvEmotes.addAll((await _globalCache)!);
    for (final channel in channels) {
      if (channel.provider != "twitch") {
        return;
      }
      _channelBttvEmotes.addAll((await _localCache[channel.channelId])!);
    }

    notifyListeners();
  }

  Map<String, dynamic> get globalEmotes => _globalBttvEmotes;

  Map<String, dynamic> get channelEmotes => _channelBttvEmotes;
}

class BttvEmote {
  final String id;
  final String code;

  BttvEmote({required this.id, required this.code});

  static BttvEmote fromJson(Map<String, dynamic> json) {
    return BttvEmote(id: json['id'], code: json['code']);
  }
}
