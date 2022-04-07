import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

final _search = FirebaseFunctions.instance.httpsCallable("search");

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

class FindAChannelScreen extends StatefulWidget {
  const FindAChannelScreen({Key? key}) : super(key: key);

  @override
  _FindAChannelScreenState createState() => _FindAChannelScreenState();
}

class _FindAChannelScreenState extends State<FindAChannelScreen> {
  var _results = _search("");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: FutureBuilder<List<SearchResult>?>(
            future: _results.then((result) {
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
              print(data);
              return CustomScrollView(slivers: [
                const SliverAppBar(
                  pinned: true,
                  expandedHeight: 260.0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text('Find a Channel'),
                  ),
                ),
                SliverAppBar(
                  pinned: true,
                  title: TextField(
                      decoration: const InputDecoration(
                        hintText: 'muxfd, maybe :)',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _results = _search(value);
                        });
                      }),
                ),
                if (data == null)
                  SliverList(
                      delegate: SliverChildListDelegate(
                          [const Center(child: CircularProgressIndicator())]))
                else
                  SliverList(
                    delegate: SliverChildListDelegate(
                      data.map((data) => Text(data.displayName)).toList(),
                    ),
                  )
              ]);
            }),
      ),
    );
  }
}
