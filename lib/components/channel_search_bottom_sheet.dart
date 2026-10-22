import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_search_results.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/user.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

const _providerPreferenceKey = "channel_search_provider";

class ChannelSearchBottomSheetWidget extends StatefulWidget {
  final ScrollController? controller;
  final void Function(Channel) onChannelSelect;
  final void Function(Channel)? onRaid;
  final bool? isRaid;
  final ChannelSearch? search;

  /// Adds a swiped result to [channels] without closing the sheet,
  /// replacing the one on its provider.
  final void Function(Channel)? onChannelAdd;

  /// The channels a swiped result is added to.
  final List<Channel> channels;

  /// Shown above the results.
  final Widget? header;

  const ChannelSearchBottomSheetWidget({
    super.key,
    this.controller,
    required this.onChannelSelect,
    this.onRaid,
    this.isRaid,
    this.search,
    this.onChannelAdd,
    this.channels = const [],
    this.header,
  });

  @override
  State<ChannelSearchBottomSheetWidget> createState() =>
      _ChannelSearchBottomSheetWidgetState();
}

class _ChannelSearchBottomSheetWidgetState
    extends State<ChannelSearchBottomSheetWidget> {
  final _searchController = TextEditingController();
  var _value = "";
  var _raid = false;
  var _provider = "twitch";
  var _providerChosen = false;

  @override
  void initState() {
    super.initState();
    _raid = widget.isRaid ?? false;
    try {
      final userProvider =
          Provider.of<UserModel>(
            context,
            listen: false,
          ).userChannels.firstOrNull?.provider;
      if (searchProviders.containsKey(userProvider)) {
        _provider = userProvider!;
      }
    } on ProviderNotFoundException {
      // no signed-in user to default to.
    }
    _loadProvider();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProvider() async {
    try {
      final prefs = await StreamingSharedPreferences.instance;
      final saved = prefs.getString(_providerPreferenceKey, defaultValue: "");
      if (mounted &&
          !_providerChosen &&
          searchProviders.containsKey(saved.getValue())) {
        setState(() => _provider = saved.getValue());
      }
    } catch (_) {
      // storage is best effort.
    }
  }

  Future<void> _setProvider(String provider) async {
    setState(() {
      _provider = provider;
      _providerChosen = true;
    });
    try {
      final prefs = await StreamingSharedPreferences.instance;
      await prefs.setString(_providerPreferenceKey, provider);
    } catch (_) {
      // storage is best effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final onChannelAdd =
        _raid && widget.onRaid != null ? null : widget.onChannelAdd;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _raid && widget.onRaid != null
                      ? AppLocalizations.of(context)!.raidAChannel
                      : AppLocalizations.of(context)!.searchChannels,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (widget.onRaid != null)
                Switch.adaptive(
                  value: _raid,
                  onChanged: (value) => setState(() => _raid = value),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            textInputAction: TextInputAction.search,
            autofocus: true,
            controller: _searchController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
              prefixIcon: PopupMenuButton<String>(
                initialValue: _provider,
                tooltip: "",
                onSelected: _setProvider,
                itemBuilder:
                    (context) => [
                      for (final entry in searchProviders.entries)
                        PopupMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(searchProviders[_provider]!),
                      const Icon(Icons.arrow_drop_down, size: 20),
                    ],
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: AnimatedScale(
                scale: _value == "" ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  child: const Icon(Icons.cancel),
                  onTap: () {
                    _searchController.clear();
                    setState(() => _value = "");
                  },
                ),
              ),
              hintText: "muxfd",
            ),
            onChanged: (value) {
              setState(() {
                _value = value;
              });
            },
          ),
          Expanded(
            child: ChannelSearchResultsWidget(
              query: _value,
              provider: _provider,
              search: widget.search,
              controller: widget.controller,
              onChannelSelect: (channel) {
                if (_raid && widget.onRaid != null) {
                  FirebaseAnalytics.instance.logEvent(
                    name: "raid",
                    parameters: {"channelId": channel.channelId},
                  );
                  widget.onRaid!(channel);
                } else {
                  FirebaseAnalytics.instance.logEvent(
                    name: "channel_select",
                    parameters: {"channelId": channel.channelId},
                  );
                  widget.onChannelSelect(channel);
                }
                Navigator.of(context).pop();
              },
              isShowOnlyOnline: _raid && widget.onRaid != null,
              onChannelAdd: onChannelAdd,
              channels: widget.channels,
              header: widget.header,
            ),
          ),
        ],
      ),
    );
  }
}
