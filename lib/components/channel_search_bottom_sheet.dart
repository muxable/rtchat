import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/models/channels.dart';

class ChannelSearchBottomSheetWidget extends StatefulWidget {
  final ScrollController? controller;
  final void Function(Channel) onChannelSelect;
  final void Function(Channel)? onRaid;

  const ChannelSearchBottomSheetWidget(
      {Key? key, this.controller, required this.onChannelSelect, this.onRaid})
      : super(key: key);

  @override
  State<ChannelSearchBottomSheetWidget> createState() =>
      _ChannelSearchBottomSheetWidgetState();
}

class _ChannelSearchBottomSheetWidgetState
    extends State<ChannelSearchBottomSheetWidget> {
  final _searchController = TextEditingController();
  var _value = "";
  var _raid = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(
                child: Text(
                    _raid
                        ? AppLocalizations.of(context)!.raidAChannel
                        : AppLocalizations.of(context)!.searchChannels,
                    style: Theme.of(context).textTheme.headlineMedium)),
            if (widget.onRaid != null)
              Switch.adaptive(
                  value: _raid,
                  onChanged: (value) => setState(() => _raid = value))
          ]),
          const SizedBox(height: 16),
          TextField(
              textInputAction: TextInputAction.search,
              autofocus: true,
              controller: _searchController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none),
                  filled: true,
                  hintStyle:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                  prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text("twitch.tv/")),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  suffixIcon: AnimatedScale(
                    scale: _value == "" ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                        child: const Icon(Icons.cancel),
                        onTap: () {
                          _searchController.clear();
                          setState(() => _value = "");
                        }),
                  ),
                  hintText: "muxfd"),
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
              if (_raid) {
                FirebaseAnalytics.instance.logEvent(
                    name: "raid", parameters: {"channelId": channel.channelId});
                widget.onRaid!(channel);
              } else {
                FirebaseAnalytics.instance.logEvent(
                    name: "channel_select",
                    parameters: {"channelId": channel.channelId});
                widget.onChannelSelect(channel);
              }
              Navigator.of(context).pop();
            },
            isShowOnlyOnline: _raid,
          ))
        ],
      ),
    );
  }
}
