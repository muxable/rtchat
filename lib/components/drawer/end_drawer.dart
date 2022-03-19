import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/channels.dart';

class LeftDrawerWidget extends StatefulWidget {
  const LeftDrawerWidget({Key? key}) : super(key: key);

  @override
  State<LeftDrawerWidget> createState() => LeftDrawerWidgetState();
}

class LeftDrawerWidgetState extends State<LeftDrawerWidget> {
  Future<dynamic>? viewersFuture;

  _viewersFuture(String channel) async {
    Uri uri = Uri.parse('https://tmi.twitch.tv/group/user/${channel}/chatters');
    final res = await http.get(uri);
    if (res.statusCode == 200) {
      List<String> broadcasterList =
          List<String>.from(jsonDecode(res.body)['chatters']['broadcaster']);
      List<String> moderatorList =
          List<String>.from(jsonDecode(res.body)['chatters']['moderators']);
      List<String> vipList =
          List<String>.from(jsonDecode(res.body)['chatters']['vips']);
      List<String> viewerList =
          List<String>.from(jsonDecode(res.body)['chatters']['viewers']);

      return {
        "broadcaster": broadcasterList,
        "moderators": moderatorList,
        "vips": vipList,
        "viewers": viewerList
      };
    } else {
      return {"broadcaster": [], "moderators": [], "vips": [], "viewers": []};
    }
  }

  @override
  void initState() {
    print('left drawer init state');
    final channelsModel = Provider.of<ChannelsModel>(context, listen: false);
    final channel = channelsModel.subscribedChannels.first;
    viewersFuture = _viewersFuture(channel.displayName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
            return CustomScrollView(
              slivers: [
                // const SliverSearchBarWidget(),
                SliverList(
                  delegate: SliverChildListDelegate(
                    const [
                      SizedBox(
                        height: 56,
                      )
                    ],
                  ),
                ),
                const SliverTitleWidget(title: "Broadcaster"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(broadcasterList![index]),
                    ),
                    childCount: broadcasterList!.length,
                  ),
                ),
                const SliverTitleWidget(title: "Moderators"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(moderatorList![index]),
                    ),
                    childCount: moderatorList!.length,
                  ),
                ),
                const SliverTitleWidget(title: "Community VIPs"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(vipList![index]),
                    ),
                    childCount: vipList!.length,
                  ),
                ),
                const SliverTitleWidget(title: "Viewers"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(viewerList![index]),
                    ),
                    childCount: viewerList!.length,
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
