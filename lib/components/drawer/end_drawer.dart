import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/drawer/endrawer/viewers_list_model.dart';

class LeftDrawerWidget extends StatefulWidget {
  const LeftDrawerWidget({Key? key}) : super(key: key);

  @override
  State<LeftDrawerWidget> createState() => LeftDrawerWidgetState();
}

class LeftDrawerWidgetState extends State<LeftDrawerWidget> {
  Future<dynamic>? viewersFuture;
  late ViewersListModel viewersListModel;

  _viewersFuture(String channel) async {
    Uri uri = Uri.parse('https://tmi.twitch.tv/group/user/$channel/chatters');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return {"broadcaster": [], "moderators": [], "vips": [], "viewers": []};
    } else {
      final jsonBody = jsonDecode(res.body);
      List<String> broadcasterList =
          List<String>.from(jsonBody['chatters']['broadcaster']);
      List<String> moderatorList =
          List<String>.from(jsonBody['chatters']['moderators']);
      List<String> vipList = List<String>.from(jsonBody['chatters']['vips']);
      List<String> viewerList =
          List<String>.from(jsonBody['chatters']['viewers']);

      return {
        "broadcaster": broadcasterList,
        "moderators": moderatorList,
        "vips": vipList,
        "viewers": viewerList
      };
    }
  }

  @override
  void initState() {
    final channelsModel = Provider.of<ChannelsModel>(context, listen: false);
    final channel = channelsModel.subscribedChannels.first;
    viewersFuture = _viewersFuture(channel.displayName.toLowerCase());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    return Container(
      color: isDarkMode
          ? Colors.black.withOpacity(0.85)
          : Colors.white.withOpacity(0.9),
      child: FutureBuilder(
        future: viewersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            Map<String, List<String>> data =
                snapshot.data as Map<String, List<String>>;
            final broadcasterList = data['broadcaster'];
            final moderatorList = data['moderators'];
            final vipList = data['vips'];
            final viewerList = data['viewers'];
            final viewersListModel =
                Provider.of<ViewersListModel>(context, listen: false);
            viewersListModel.init(
              [...broadcasterList!],
              [...moderatorList!],
              [...vipList!],
              [...viewerList!],
            );
            return Consumer<ViewersListModel>(builder: (context, model, child) {
              final broadcasterList = model.filteredBroadcasterList;
              final moderatorList = model.filteredModeratorList;
              final vipList = model.filteredVipList;
              final viewerList = model.filteredViewerList;
              return CustomScrollView(
                slivers: [
                  const SliverSearchBarWidget(),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      const [
                        SizedBox(
                          height: 8,
                        )
                      ],
                    ),
                  ),
                  if (broadcasterList.isNotEmpty) ...[
                    const SliverTitleWidget(title: "Broadcaster"),
                  ],
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(broadcasterList[index]),
                      ),
                      childCount: broadcasterList.length,
                    ),
                  ),
                  if (moderatorList.isNotEmpty) ...[
                    const SliverTitleWidget(title: "Moderators")
                  ],
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(moderatorList[index]),
                      ),
                      childCount: moderatorList.length,
                    ),
                  ),
                  if (vipList.isNotEmpty) ...[
                    const SliverTitleWidget(title: "Community VIPs")
                  ],
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(vipList[index]),
                      ),
                      childCount: vipList.length,
                    ),
                  ),
                  if (viewerList.isNotEmpty) ...[
                    const SliverTitleWidget(title: "Viewers")
                  ],
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(viewerList[index]),
                        );
                      },
                      childCount: viewerList.length,
                      addAutomaticKeepAlives: true,
                    ),
                  ),
                ],
              );
            });
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
