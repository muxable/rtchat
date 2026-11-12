import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';

class TwitchBadgeWidget extends StatelessWidget {
  final String badgeSetId;
  final String version;
  final double? height;
  final bool ignoreSettings;

  const TwitchBadgeWidget({
    super.key,
    required this.badgeSetId,
    required this.version,
    this.height,
    this.ignoreSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TwitchBadgeModel>(
      builder: (context, model, child) {
        if (!ignoreSettings && !model.isEnabled(badgeSetId)) {
          return const SizedBox();
        }
        for (final badgeSet in model.badgeSets) {
          if (badgeSet.setId != badgeSetId) {
            continue;
          }
          for (final badgeVersion in badgeSet.versions) {
            if (badgeVersion.id != version) {
              continue;
            }
            final url = Uri.tryParse(badgeVersion.imageUrl1x);
            if (url == null) {
              return const SizedBox();
            }
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Image(
                image: CachedNetworkImageProvider(url.toString()),
                height: height,
              ),
            );
          }
        }
        // badge not found, ignore.
        return const SizedBox();
      },
    );
  }
}
