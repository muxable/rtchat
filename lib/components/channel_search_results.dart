import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image/network.dart';
import 'package:rtchat/models/channels.dart';

final _search = FirebaseFunctions.instance.httpsCallable("search");

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SearchResult {
  final String channelId;
  final String provider;
  final String displayName;
  final bool isOnline;
  final String imageUrl;
  final String title;

  const SearchResult(
      {required this.channelId,
      required this.provider,
      required this.displayName,
      required this.isOnline,
      required this.imageUrl,
      required this.title});
}

class ChannelSearchResultsWidget extends StatelessWidget {
  final String query;
  final Function(Channel) onChannelSelect;
  final ScrollController? controller;

  const ChannelSearchResultsWidget(
      {Key? key,
      required this.query,
      required this.onChannelSelect,
      this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SearchResult>?>(
        future: _search(query).then((result) {
          return (result.data as List<dynamic>)
              .map((data) => SearchResult(
                  channelId: data['channelId'],
                  provider: data['provider'],
                  displayName: data['displayName'],
                  isOnline: data['isOnline'],
                  imageUrl: data['imageUrl'],
                  title: data['title']))
              .toList();
        }),
        initialData: null,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const CircularProgressIndicator();
          } else {
            return ListView(
              controller: controller,
              children: data
                  .map((result) => ListTile(
                      leading: Container(
                        child: CircleAvatar(
                          backgroundImage:
                              NetworkImageWithRetry(result.imageUrl),
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: result.isOnline ? Colors.green : Colors.red,
                            width: 2.0,
                          ),
                        ),
                      ),
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
          }
        });
  }
}
