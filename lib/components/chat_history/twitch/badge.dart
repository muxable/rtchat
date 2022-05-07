import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:flutter_image/flutter_image.dart';

class TwitchBadgeWidget extends StatelessWidget {
  final String channelId;
  final String badge;
  final String version;
  final double? height;

  const TwitchBadgeWidget(
      {Key? key,
      required this.channelId,
      required this.badge,
      required this.version,
      this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TwitchBadgeModel>(builder: (context, model, child) {
      if (!model.isEnabled("$badge/$version")) {
        return const SizedBox();
      }
      final url = model.badgeSets["$badge/$version"]?["image_url_4x"];
      if (url == null) {
        return const SizedBox();
      }
      return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Image(image: NetworkImageWithRetry(url), height: height));
    });
  }
}
