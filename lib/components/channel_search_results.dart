import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';

final _search = FirebaseFunctions.instance.httpsCallable("search");

Future<List<SearchResult>> fastSearch() async {
  // fast query firestore and slow query the functions. tag firestore results
  // with isPromoted = true.
  final snapshot = await FirebaseFirestore.instance
      .collection("metadata")
      .where("lastActiveAt",
          isGreaterThan: DateTime.now().subtract(const Duration(days: 3)))
      .orderBy("lastActiveAt", descending: true)
      .limit(5)
      .get();
  return snapshot.docs.map((doc) {
    final data = doc.data();
    final tokens = doc.id.split(":");
    final provider = tokens[0];
    final channelId = tokens[1];
    return SearchResult(
        channelId: channelId,
        provider: provider,
        displayName: data['displayName'],
        isOnline: data['onlineAt'] != null,
        imageUrl: Uri.parse(
            "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId"),
        title: "${data['categoryName']} - ${data['title']}",
        isPromoted: true);
  }).toList();
}

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SearchResult {
  final String channelId;
  final String provider;
  final String displayName;
  final bool isOnline;
  final Uri imageUrl;
  final String title;
  final bool isPromoted;

  const SearchResult(
      {required this.channelId,
      required this.provider,
      required this.displayName,
      required this.isOnline,
      required this.imageUrl,
      required this.title,
      required this.isPromoted});
}

class ChannelSearchResultsWidget extends StatelessWidget {
  final String query;
  final Function(Channel) onChannelSelect;
  final ScrollController? controller;
  final Future<List<SearchResult>> _fastSearch = fastSearch();

  ChannelSearchResultsWidget(
      {Key? key,
      required this.query,
      required this.onChannelSelect,
      this.controller})
      : super(key: key);

  Stream<List<SearchResult>> search() async* {
    final fast = await _fastSearch;
    final fastFiltered = fast.where((result) =>
        result.displayName.toLowerCase().contains(query.toLowerCase()));
    yield fastFiltered.toList();
    final slow = await _search(query).then((result) {
      return (result.data as List<dynamic>)
          .map((data) => SearchResult(
              channelId: data['channelId'],
              provider: data['provider'],
              displayName: data['displayName'],
              isOnline: data['isOnline'],
              imageUrl: Uri.parse(data['imageUrl']),
              title: data['title'],
              isPromoted: false))
          .toList();
    });
    final slowFiltered = slow.where((result) =>
        !fastFiltered.any((element) => element.channelId == result.channelId));
    yield [...fastFiltered, ...slowFiltered];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      children: [
        StreamBuilder<List<SearchResult>>(
          stream: search(),
          builder: (context, snapshot) {
            return Column(
              children: (snapshot.data ?? [])
                  .map((result) => ListTile(
                      leading: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: result.isOnline
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Stack(alignment: Alignment.center, children: [
                            CircleAvatar(
                              backgroundImage:
                                  ResilientNetworkImage(result.imageUrl),
                              backgroundColor: Colors.transparent,
                            ),
                            Positioned(
                                right: -4,
                                bottom: -4,
                                child: result.isPromoted
                                    ? Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
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
                      title: Text(result.displayName),
                      subtitle: Text(result.title),
                      onTap: () {
                        onChannelSelect(Channel(
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
