import 'package:flutter/material.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/models/channels.dart';

class ChannelSearchBottomSheetWidget extends StatefulWidget {
  final ScrollController? controller;
  final void Function(Channel) onChannelSelect;

  const ChannelSearchBottomSheetWidget(
      {Key? key, this.controller, required this.onChannelSelect})
      : super(key: key);

  @override
  State<ChannelSearchBottomSheetWidget> createState() =>
      _ChannelSearchBottomSheetWidgetState();
}

class _ChannelSearchBottomSheetWidgetState
    extends State<ChannelSearchBottomSheetWidget> {
  final _searchController = TextEditingController();
  var _value = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Search Channels',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.headlineMedium),
          ),
          const SizedBox(height: 16),
          TextField(
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  filled: true,
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text("twitch.tv/",
                          style: TextStyle(color: Colors.grey[700]))),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: GestureDetector(
                      child: const Icon(Icons.cancel),
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _value = "";
                        });
                      }),
                  hintText: "muxfd",
                  fillColor: Colors.white70),
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                setState(() {
                  _value = value;
                });
              }),
          Expanded(
              child: ChannelSearchResultsWidget(
            query: _value,
            controller: widget.controller,
            onChannelSelect: (channel) {
              widget.onChannelSelect(channel);
              Navigator.of(context).pop();
            },
          ))
        ],
      ),
    );
  }
}
