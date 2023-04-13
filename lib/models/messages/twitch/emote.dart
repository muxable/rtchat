import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';

Future<List<Emote>> getEmotes(Channel channel) async {
  final temp = await getTemporaryDirectory();
  final cacheFile = File('${temp.path}/emotes/${channel.toString()}.json');
  if (await cacheFile.exists()) {
    final stats = await cacheFile.stat();
    if (stats.modified
        .isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      final json = await cacheFile.readAsString();
      return (jsonDecode(json) as List).map((e) => Emote.fromJson(e)).toList();
    }
  }

  final response = await FirebaseFunctions.instance.httpsCallable("getEmotes")({
    "provider": channel.provider,
    "channelId": channel.channelId,
  });
  final json = jsonEncode(response.data);
  await cacheFile.create(recursive: true);
  await cacheFile.writeAsString(json);

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

  get uri =>
      Uri.tryParse(imageUrl.startsWith("//") ? "https:$imageUrl" : imageUrl);

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
