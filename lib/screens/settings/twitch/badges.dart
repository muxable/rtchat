import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/twitch/badge.dart';

class TwitchBadgesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TwitchBadgeModel>(builder: (context, model, child) {
        final keys = model.badgeSets.keys.toList()
          ..sort((a, b) => model.badgeSets[a]["title"]
              .compareTo(model.badgeSets[b]["title"]));
        return CustomScrollView(slivers: <Widget>[
          SliverAppBar(
              pinned: true,
              expandedHeight: 250.0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Twitch badges'),
              ),
              actions: [
                Row(children: [
                  Text("Select all"),
                  Checkbox(
                      tristate: true,
                      value: model.enabledCount == 0
                          ? false
                          : (model.enabledCount == model.badgeCount
                              ? true
                              : null),
                      onChanged: (value) {
                        model.setAllEnabled(value ?? false);
                      })
                ]),
              ]),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final badgeSet = model.badgeSets[keys[index]];
                return CheckboxListTile(
                    secondary: Image(
                        alignment: Alignment.center,
                        image: NetworkImage(badgeSet["image_url_4x"]),
                        height: 36),
                    title: Text(badgeSet["title"],
                        overflow: TextOverflow.ellipsis),
                    subtitle: badgeSet["description"] == badgeSet["title"]
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
    );
  }
}
