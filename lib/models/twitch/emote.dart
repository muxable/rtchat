import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:rtchat/models/channels.dart';

class Emote {
  final int id;
  final String code;
  final String source;

  Emote(this.id, this.code, this.source);

  Emote.fromMap(dynamic input)
      : id = input['id'],
        code = input['code'],
        source = 'https://static-cdn.jtvnw.net/emoticons/v1/${input['id']}/1.0';
}

final getUserEmotes = FirebaseFunctions.instance.httpsCallable("getUserEmotes");

class TwitchEmoteSets extends ChangeNotifier {
  Map<String, List<Emote>> emotes = {};

  TwitchEmoteSets();

  Future<void> subscribe(Set<Channel> channels) async {
    emotes.clear();

    for (final channel in channels) {
      if (channel.provider != "twitch") {
        continue;
      }

      if (emotes.containsKey(channel.channelId)) {
        continue;
      }

      final response = await getUserEmotes({
        "provider": channel.provider,
        "channelId": channel.channelId,
      });

      var emoteList = response.data['emotes'] as List;
      List<Emote> parsedEmotes = emoteList
          .map((individualEmote) => Emote.fromMap(individualEmote))
          .toList();

      emotes[channel.channelId] = parsedEmotes;
    }

    notifyListeners();
  }
}