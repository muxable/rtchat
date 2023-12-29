import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';

class TwitchBadgeWidget extends StatelessWidget {
  final String badgeSetId;
  final String version;
  final double? height;

  const TwitchBadgeWidget(
      {super.key, required this.badgeSetId, required this.version, this.height});

  @override
  Widget build(BuildContext context) {
    return Consumer<TwitchBadgeModel>(builder: (context, model, child) {
      if (!model.isEnabled(badgeSetId)) {
        return const SizedBox();
      }
      for (final badgeSet in model.badgeSets) {
        if (badgeSet.setId != badgeSetId) {
          continue;
        }
        for (final version in badgeSet.versions) {
          if (version.id != this.version) {
            continue;
          }
          final url = Uri.tryParse(version.imageUrl1x);
          if (url == null) {
            return const SizedBox();
          }
          return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Image(image: ResilientNetworkImage(url), height: height));
        }
      }
      // badge not found, ignore.
      return const SizedBox();
    });
  }
}
