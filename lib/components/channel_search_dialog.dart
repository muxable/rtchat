import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rxdart/rxdart.dart';

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

class ChannelSearchDialog extends StatefulWidget {
  final void Function(Channel) onSelect;

  const ChannelSearchDialog({Key? key, required this.onSelect})
      : super(key: key);

  @override
  _ChannelSearchDialogState createState() => _ChannelSearchDialogState();
}

class _ChannelSearchDialogState extends State<ChannelSearchDialog> {
  final _searches = StreamController<String>();
  late final Stream<List<SearchResult>> _results;

  @override
  void initState() {
    super.initState();

    _results = _searches.stream
        .sample(Stream.periodic(const Duration(seconds: 1)))
        .switchMap((value) async* {
      if (value.isEmpty) {
        yield [];
      } else {
        final result = await _search(value);
        yield (result.data as List<dynamic>)
            .map((data) => SearchResult(
                channelId: data['channelId'],
                provider: data['provider'],
                displayName: data['displayName'],
                isOnline: data['isOnline'],
                imageUrl: data['imageUrl'],
                title: data['title']))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(children: [
        TextField(
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            labelText: 'Search for a channel',
          ),
          onChanged: (value) => _searches.add(value),
        ),
        StreamBuilder(
          stream: _results,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container();
            }
            final data = snapshot.data as List<SearchResult>;
            return Expanded(
                child: ListView(
                    children: data.map((result) {
              return ListTile(
                  leading: Container(
                    child: CircleAvatar(
                      backgroundImage: NetworkImageWithRetry(result.imageUrl),
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
                    widget.onSelect(Channel(
                        result.provider, result.channelId, result.displayName));
                  });
            }).toList()));
          },
        ),
      ]),
    );
  }
}
