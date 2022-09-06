import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:rtchat/models/channels.dart';

Future<List<Emote>> getEmotes(Channel channel) async {
  final response = await FirebaseFunctions.instance.httpsCallable("getEmotes")({
    "provider": channel.provider,
    "channelId": channel.channelId,
  });

  return (response.data as List)
      .map((individualEmote) => Emote.fromJson(individualEmote))
      .toList();
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

  get uri => Uri.tryParse(imageUrl);

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
