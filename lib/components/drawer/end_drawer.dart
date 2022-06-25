import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rtchat/components/drawer/sliver_search_bar.dart';
import 'package:rtchat/components/drawer/sliver_title.dart';
import 'package:rtchat/models/channels.dart';

class LeftDrawerWidget extends StatefulWidget {
  final Channel channel;

  const LeftDrawerWidget({required this.channel, Key? key}) : super(key: key);

  @override
  State<LeftDrawerWidget> createState() => LeftDrawerWidgetState();
}

class LeftDrawerWidgetState extends State<LeftDrawerWidget> {
  Future<dynamic>? viewersFuture;

  List<String> originalBroadcasterList = [];
  List<String> originalModeratorList = [];
  List<String> originalVipList = [];
  List<String> originalViewerList = [];

  List<String> filteredBroadcasterList = [];
  List<String> filteredModeratorList = [];
  List<String> filteredVipList = [];
  List<String> filteredViewerList = [];

  late final SliverSearchBarWidget sliverSearchBarWidget;

  Future<List<String>> filterList(
      List<String> list, String searchBarText) async {
    return list
        .where(((String element) => element.contains(searchBarText)))
        .toList();
  }

  Future<List<String>> copyList(List<String> list) async {
    return [...list];
  }

  init(List<String> broadcasterList, List<String> moderatorList,
      List<String> vipList, List<String> viewerList) {
    Future.wait([
      copyList(broadcasterList).then((value) =>
          {originalBroadcasterList = value, filteredBroadcasterList = value}),
      copyList(moderatorList).then((value) =>
          {originalModeratorList = value, filteredModeratorList = value}),
      copyList(vipList)
          .then((value) => {originalVipList = value, filteredVipList = value}),
      copyList(viewerList).then(
          (value) => {originalViewerList = value, filteredViewerList = value}),
    ]);
  }

  void onFilteredByText(String searchBarText) {
    if (searchBarText.isEmpty) {
      setState(() {
        filteredBroadcasterList = originalBroadcasterList;
        filteredModeratorList = originalModeratorList;
        filteredVipList = originalVipList;
        filteredViewerList = originalViewerList;
      });
    } else {
      Future.wait([
        filterList(originalBroadcasterList, searchBarText)
            .then((value) => filteredBroadcasterList = value),
        filterList(originalModeratorList, searchBarText)
            .then((value) => filteredModeratorList = value),
        filterList(originalVipList, searchBarText)
            .then((value) => filteredVipList = value),
        filterList(originalViewerList, searchBarText)
            .then((value) => filteredViewerList = value),
      ]);
      setState(() {
        filteredBroadcasterList = filteredBroadcasterList;
        filteredModeratorList = filteredModeratorList;
        filteredVipList = filteredVipList;
        filteredViewerList = filteredViewerList;
      });
    }
  }

  _viewersFuture(String channel) async {
    Uri uri = Uri.parse('https://tmi.twitch.tv/group/user/$channel/chatters');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      await init([], [], [], []);
    } else {
      final jsonBody = jsonDecode(res.body);
      List<String> broadcasterList =
          List<String>.from(jsonBody['chatters']['broadcaster']);
      List<String> moderatorList =
          List<String>.from(jsonBody['chatters']['moderators']);
      List<String> vipList = List<String>.from(jsonBody['chatters']['vips']);
      List<String> viewerList =
          List<String>.from(jsonBody['chatters']['viewers']);

      await init(
        [...broadcasterList],
        [...moderatorList],
        [...vipList],
        [...viewerList],
      );
    }
  }

  @override
  void initState() {
    viewersFuture = _viewersFuture(widget.channel.displayName.toLowerCase());
    sliverSearchBarWidget = SliverSearchBarWidget(
      onFilterBySearchBarText: onFilteredByText,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).canvasColor,
      child: FutureBuilder(
        future: viewersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.only(top: 24),
                  sliver: SliverAppBar(
                      actions: const [SizedBox()],
                      //disable the drawer icon that appears on the right of the app bar
                      centerTitle: false,
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'Search Viewers',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      backgroundColor: Colors.transparent,
                      automaticallyImplyLeading: false),
                ),
                sliverSearchBarWidget,
                if (filteredBroadcasterList.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Broadcaster"),
                  ),
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(filteredBroadcasterList[index]),
                    ),
                    childCount: filteredBroadcasterList.length,
                  ),
                ),
                if (filteredModeratorList.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Moderators"),
                  )
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(filteredModeratorList[index]),
                    ),
                    childCount: filteredModeratorList.length,
                  ),
                ),
                if (filteredVipList.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Community VIPs"),
                  )
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(filteredVipList[index]),
                    ),
                    childCount: filteredVipList.length,
                  ),
                ),
                if (filteredViewerList.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.only(top: 8, left: 8),
                    sliver: SliverTitleWidget(title: "Viewers"),
                  )
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: Text(filteredViewerList[index]),
                      );
                    },
                    childCount: filteredViewerList.length,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
