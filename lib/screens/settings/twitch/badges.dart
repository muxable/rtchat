import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';

class TwitchBadgesScreen extends StatelessWidget {
  const TwitchBadgesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Consumer<TwitchBadgeModel>(builder: (context, model, child) {
          final keys = model.badgeSets.keys.toList()
            ..sort((a, b) => model.badgeSets[a]["title"]
                .compareTo(model.badgeSets[b]["title"]));
          return CustomScrollView(slivers: <Widget>[
            SliverAppBar(
                pinned: true,
                expandedHeight: 250.0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(AppLocalizations.of(context)!.twitchBadges),
                ),
                actions: [
                  Row(children: [
                    Text(AppLocalizations.of(context)!.selectAll),
                    Theme(
                      data: theme.copyWith(
                          unselectedWidgetColor: theme.colorScheme.onTertiary),
                      child: Checkbox(
                        tristate: true,
                        value: model.enabledCount == 0
                            ? false
                            : (model.enabledCount == model.badgeCount
                                ? true
                                : null),
                        onChanged: (value) {
                          model.setAllEnabled(value ?? false);
                        },
                      ),
                    )
                  ]),
                ]),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badgeSet = model.badgeSets[keys[index]];
                  final image = ResilientNetworkImage(
                      Uri.parse(badgeSet["image_url_4x"]));
                  return CheckboxListTile(
                      secondary: CrossFadeImage(
                          alignment: Alignment.center,
                          placeholder: image.placeholderImage,
                          image: image,
                          height: 36),
                      title: Text(badgeSet["title"],
                          overflow: TextOverflow.ellipsis),
                      subtitle: badgeSet["description"] == badgeSet["title"] ||
                              badgeSet["description"].trim().isEmpty
                          ? null
                          : Text(badgeSet["description"],
                              overflow: TextOverflow.ellipsis),
                      value: model.isEnabled(keys[index]),
                      onChanged: (value) {
                        model.setEnabled(keys[index], value ?? false);
                      });
                },
                childCount: keys.length,
              ),
            ),
          ]);
        }),
      ),
    );
  }
}
