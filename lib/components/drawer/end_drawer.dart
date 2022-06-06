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
                SliverAppBar(
                    actions: <Widget>[Container()],
                    //disable the drawer icon that appears on the right of the app bar
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: false,
                      titlePadding:
                          const EdgeInsets.only(left: 32.0, top: 10.0),
                      title: Text(
                        'Search Viewers',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(0, 96, 125, 139),
                    automaticallyImplyLeading: false),
                sliverSearchBarWidget,
                SliverList(
                  delegate: SliverChildListDelegate(
                    const [
                      SizedBox(
                        height: 8,
                      ),
                    ],
                  ),
                ),
                if (filteredBroadcasterList.isNotEmpty) ...[
                  const SliverTitleWidget(title: "Broadcaster"),
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(filteredBroadcasterList[index]),
                    ),
                    childCount: filteredBroadcasterList.length,
                  ),
                ),
                if (filteredModeratorList.isNotEmpty) ...[
                  if (filteredBroadcasterList.isNotEmpty) ...[
                    //if broadcaster list exists, check if moderators list exists and render a divider
                    const SliverPadding(
                        padding: EdgeInsets.symmetric(
                            vertical: 7.0, horizontal: 0.0)),
                    const SliverToBoxAdapter(
                        child: Divider(
                      height: 1,
                      endIndent: 32,
                      color: Color.fromARGB(95, 37, 34, 34),
                      indent: 32,
                    )),
                  ],
                  const SliverTitleWidget(title: "Moderators")
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(filteredModeratorList[index]),
                    ),
                    childCount: filteredModeratorList.length,
                  ),
                ),
                if (filteredVipList.isNotEmpty) ...[
                  if (filteredModeratorList.isNotEmpty ||
                      filteredBroadcasterList.isNotEmpty) ...[
                    //if vip list exists, then check if moderator OR broadcaster list exists to render a divider
                    const SliverPadding(
                        padding: EdgeInsets.symmetric(
                            vertical: 7.0, horizontal: 0.0)),
                    const SliverToBoxAdapter(
                        child: Divider(
                      height: 1,
                      endIndent: 32,
                      color: Color.fromARGB(95, 37, 34, 34),
                      indent: 32,
                    )),
                  ],
                  const SliverTitleWidget(title: "Community VIPs")
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) => Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(filteredVipList[index]),
                    ),
                    childCount: filteredVipList.length,
                  ),
                ),
                if (filteredViewerList.isNotEmpty) ...[
                  if (filteredVipList.isNotEmpty ||
                      filteredModeratorList.isNotEmpty ||
                      filteredBroadcasterList.isNotEmpty) ...[
                    // if viewer list exists,
                    const SliverPadding(
                        padding: EdgeInsets.symmetric(
                            vertical: 7.0, horizontal: 0.0)),
                    const SliverToBoxAdapter(
                        child: Divider(
                      height: 1,
                      endIndent: 32,
                      color: Color.fromARGB(95, 37, 34, 34),
                      indent: 32,
                    )),
                  ],
                  const SliverTitleWidget(title: "Viewers")
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(filteredViewerList[index]),
                      );
                    },
                    childCount: filteredViewerList.length,
                    addAutomaticKeepAlives: true,
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
