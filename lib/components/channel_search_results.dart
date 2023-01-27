import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';

final _search = FirebaseFunctions.instance.httpsCallable("search");

Future<List<SearchResult>> fastSearch() async {
  // fast query firestore and slow query the functions. tag firestore results
  // with isPromoted = true.
  final snapshot = await FirebaseFirestore.instance
      .collection("channels")
      .where("lastActiveAt",
          isGreaterThan: DateTime.now().subtract(const Duration(days: 3)))
      .orderBy("lastActiveAt", descending: true)
      .limit(250)
      .get();
  return snapshot.docs
      .where((doc) => doc.data().containsKey("displayName"))
      .map((doc) {
    final data = doc.data();
    final tokens = doc.id.split(":");
    final provider = tokens[0];
    final channelId = tokens[1];
    String? title;
    if (data['title'] != null && data['categoryName'] != null) {
      title = "${data['categoryName']} - ${data['title']}";
    } else if (data['title'] != null) {
      title = data['title'];
    } else if (data['categoryName'] != null) {
      title = data['categoryName'];
    }
    return SearchResult(
        channelId: channelId,
        provider: provider,
        displayName: data['displayName'],
        isOnline: data['onlineAt'] != null,
        imageUrl: Uri.parse(
            "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId"),
        title: title,
        language: data['language'],
        isPromoted: true);
  }).toList();
}

Stream<List<SearchResult>> search(String query, bool isShowOnlyOnline) async* {
  final fast = await fastSearch();
  final fastFiltered = fast.where((result) =>
      result.displayName.toLowerCase().contains(query.toLowerCase()));
  final fastRanked = [
    ...fastFiltered.where((element) => element.isOnline),
    ...fastFiltered.where((element) => !element.isOnline)
  ].take(5);
  yield fastRanked.toList();
  final slow = await _search(query).then((result) {
    return (result.data as List<dynamic>)
        .map((data) => SearchResult(
            channelId: data['channelId'],
            provider: data['provider'],
            displayName: data['displayName'],
            isOnline: data['isOnline'],
            imageUrl: Uri.parse(data['imageUrl']),
            title: data['title'],
            language: data['language'],
            isPromoted: false))
        .toList();
  });
  final slowFiltered = slow.where((result) =>
      !fastFiltered.any((element) => element.channelId == result.channelId) &&
      (!isShowOnlyOnline || result.isOnline));
  yield [...fastRanked, ...slowFiltered];
}

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SearchResult {
  final String channelId;
  final String provider;
  final String displayName;
  final bool isOnline;
  final Uri imageUrl;
  final String? title;
  final bool isPromoted;
  final String? language;

  const SearchResult(
      {required this.channelId,
      required this.provider,
      required this.displayName,
      required this.isOnline,
      required this.imageUrl,
      required this.title,
      required this.isPromoted,
      required this.language});

  ResilientNetworkImage get image => ResilientNetworkImage(imageUrl);
}

class ChannelSearchResultsWidget extends StatefulWidget {
  final String query;
  final bool isShowOnlyOnline;
  final Function(Channel) onChannelSelect;
  final ScrollController? controller;

  const ChannelSearchResultsWidget(
      {Key? key,
      required this.query,
      required this.onChannelSelect,
      required this.isShowOnlyOnline,
      this.controller})
      : super(key: key);

  @override
  State<ChannelSearchResultsWidget> createState() =>
      _ChannelSearchResultsWidgetState();
}

class _ChannelSearchResultsWidgetState
    extends State<ChannelSearchResultsWidget> {
  late Stream<List<SearchResult>> _results;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _results = search(widget.query, widget.isShowOnlyOnline);
  }

  @override
  void didUpdateWidget(covariant ChannelSearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.isShowOnlyOnline != widget.isShowOnlyOnline) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _results = search(widget.query, widget.isShowOnlyOnline);
        });
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.controller,
      children: [
        StreamBuilder<List<SearchResult>>(
          stream: _results,
          builder: (context, snapshot) {
            return Column(
              children: (snapshot.data ?? [])
                  .map((result) => ListTile(
                      leading: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: result.isOnline
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: CrossFadeImage(
                                      placeholder:
                                          result.image.placeholderImage,
                                      image: result.image,
                                      height: 48,
                                      width: 48),
                                ),
                                Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: result.isPromoted
                                        ? Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(18.0),
                                            ),
                                            child: const Icon(
                                              Icons.keyboard_double_arrow_up,
                                              color: Colors.green,
                                              size: 18.0,
                                            ),
                                          )
                                        : Container())
                              ])),
                      title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(result.displayName),
                            Text(result.language ?? "??",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                )),
                          ]),
                      subtitle:
                          result.title == null ? null : Text(result.title!),
                      onTap: () {
                        widget.onChannelSelect(Channel(
                          "twitch",
                          result.channelId,
                          result.displayName,
                        ));
                      }))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
