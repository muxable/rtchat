import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

final _search = Api.instance.callable("search");

Future<List<SearchResult>> fastSearch() async {
  // fast query firestore and slow query the functions. tag firestore results
  // with isPromoted = true.
  final snapshot =
      await FirebaseFirestore.instance
          .collection("channels")
          .where(
            "lastActiveAt",
            isGreaterThan: DateTime.now().subtract(const Duration(days: 3)),
          )
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
          login: data['login'],
          displayName: data['displayName'],
          isOnline: data['onlineAt'] != null,
          imageUrl: Uri.parse(
            "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId",
          ),
          title: title,
          language: data['language'],
          isPromoted: true,
        );
      })
      .toList();
}

// The providers channel search can target, with the prefix shown for each.
const searchProviders = {"twitch": "twitch.tv/", "kick": "kick.com/"};

typedef ChannelSearch =
    Stream<List<SearchResult>> Function(
      String query,
      String provider,
      bool isShowOnlyOnline,
    );

String _channelKey(String provider, String channelId) => '$provider:$channelId';

/// Recently active channels matching [query].
///
/// Followed channels are placed first and aren't limited to five.
/// The five-result limit applies only to other recently active channels.
List<SearchResult> filterRecentChannels(
  List<SearchResult> results,
  String query,
  String provider, {
  Set<String> followedChannelKeys = const {},
}) {
  final needle = query.toLowerCase();
  final matches = results.where(
    (result) =>
        result.provider == provider &&
        (result.displayName.toLowerCase().contains(needle) ||
            result.login.toLowerCase().contains(needle)),
  );
  final followed =
      matches
          .where(
            (result) => followedChannelKeys.contains(
              _channelKey(result.provider, result.channelId),
            ),
          )
          .toList();
  final others =
      matches
          .where(
            (result) =>
                !followedChannelKeys.contains(
                  _channelKey(result.provider, result.channelId),
                ),
          )
          .toList()
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) {
            return a.isOnline ? -1 : 1;
          }
          return 0;
        });
  return [...followed, ...others.take(5)];
}

Stream<List<SearchResult>> searchChannels(
  String query,
  String provider,
  bool isShowOnlyOnline, {
  List<Channel> followedChannels = const [],
}) async* {
  final followedForProvider =
      followedChannels
          .where((channel) => channel.provider == provider)
          .toList();
  final followedChannelKeys =
      followedForProvider
          .map((channel) => _channelKey(channel.provider, channel.channelId))
          .toSet();
  // Fetch recent channels and prioritize followed streamers.
  final recent = await fastSearch();
  // Convert followed channels missing from the recent query into search
  // results, so following a streamer doesn't depend on recent activity.
  final followedResults = followedForProvider
      .map((channel) {
        final existing = recent.where(
          (result) =>
              result.provider == channel.provider &&
              result.channelId == channel.channelId,
        );
        if (existing.isNotEmpty) {
          return existing.first;
        }
        return SearchResult(
          channelId: channel.channelId,
          provider: channel.provider,
          login: channel.displayName,
          displayName: channel.displayName,
          isOnline: false,
          imageUrl: Uri.parse(
            "https://rtirl.com/pfp.png?provider=${channel.provider}"
            "&channelId=${channel.channelId}",
          ),
          title: null,
          language: null,
          isPromoted: false,
        );
      })
      .where(
        (result) =>
            result.displayName.toLowerCase().contains(query.toLowerCase()) ||
            result.login.toLowerCase().contains(query.toLowerCase()),
      );
  final followedByKey = {
    for (final result in followedResults)
      _channelKey(result.provider, result.channelId): result,
  };
  final fastRanked = filterRecentChannels(
    recent,
    query,
    provider,
    followedChannelKeys: followedChannelKeys,
  );
  final mergedFast = <String, SearchResult>{};
  // Followed streamers always appear before other recently active streamers.
  for (final result in followedByKey.values) {
    mergedFast[_channelKey(result.provider, result.channelId)] = result;
  }
  for (final result in fastRanked) {
    mergedFast.putIfAbsent(
      _channelKey(result.provider, result.channelId),
      () => result,
    );
  }
  yield mergedFast.values.toList();
  // Fetch the full provider search.
  final slow = await _search({"query": query, "provider": provider}).then((
    result,
  ) {
    return (result.data as List<dynamic>)
        .map(
          (data) => SearchResult(
            channelId: data['channelId'],
            provider: data['provider'],
            login: data['login'],
            displayName: data['displayName'],
            isOnline: data['isOnline'],
            imageUrl: Uri.parse(data['imageUrl']),
            title: data['title'],
            language: data['language'],
            isPromoted: false,
          ),
        )
        .toList();
  });

  final combined = <String, SearchResult>{...mergedFast};
  for (final result in slow) {
    final key = _channelKey(result.provider, result.channelId);
    if (result.provider != provider || combined.containsKey(key)) {
      continue;
    }
    combined[key] = result;
  }
  yield combined.values.toList();
}

final url = Uri.https('chat.rtirl.com', '/auth/twitch/redirect');

class SearchResult {
  final String channelId;
  final String provider;
  final String login;
  final String displayName;
  final bool isOnline;
  final Uri imageUrl;
  final String? title;
  final bool isPromoted;
  final String? language;

  const SearchResult({
    required this.channelId,
    required this.provider,
    required this.login,
    required this.displayName,
    required this.isOnline,
    required this.imageUrl,
    required this.title,
    required this.isPromoted,
    required this.language,
  });

  ResilientNetworkImage get image => ResilientNetworkImage(imageUrl);

  Channel get channel => Channel(provider, channelId, displayName);
}

class ChannelSearchResultsWidget extends StatefulWidget {
  final String query;
  final String provider;
  final bool isShowOnlyOnline;
  final ChannelSearch search;
  final Function(Channel) onChannelSelect;
  final ScrollController? controller;

  /// Followed channels are always prioritized in search results.
  final List<Channel> followedChannels;

  /// Adds a swiped result to [channels], replacing the one on its provider.
  /// Results can't be swiped without it.
  final void Function(Channel)? onChannelAdd;

  /// The channels a swiped result is added to. A result already in them
  /// can't be swiped.
  final List<Channel> channels;

  /// Shown above the results, scrolling with them.
  final Widget? header;

  const ChannelSearchResultsWidget({
    super.key,
    required this.query,
    this.provider = "twitch",
    this.search = searchChannels,
    required this.onChannelSelect,
    required this.isShowOnlyOnline,
    this.controller,
    this.onChannelAdd,
    this.channels = const [],
    this.followedChannels = const [],
    this.header,
  });

  @override
  State<ChannelSearchResultsWidget> createState() =>
      _ChannelSearchResultsWidgetState();
}

class _ChannelSearchResultsWidgetState
    extends State<ChannelSearchResultsWidget> {
  late Stream<List<SearchResult>> _results;
  Timer? _debounce;
  Stream<List<SearchResult>> _createSearch() {
    if (widget.search == searchChannels) {
      return searchChannels(
        widget.query,
        widget.provider,
        widget.isShowOnlyOnline,
        followedChannels: widget.followedChannels,
      );
    }
    return widget.search(
      widget.query,
      widget.provider,
      widget.isShowOnlyOnline,
    );
  }

  @override
  void initState() {
    super.initState();
    _results = _createSearch();
  }

  @override
  void didUpdateWidget(covariant ChannelSearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.provider != widget.provider ||
        oldWidget.followedChannels != widget.followedChannels) {
      _debounce?.cancel();
      _results = _createSearch();
    } else if (oldWidget.query != widget.query) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        setState(() {
          _results = _createSearch();
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
        if (widget.header != null) widget.header!,
        StreamBuilder<List<SearchResult>>(
          stream: _results,
          builder: (context, snapshot) {
            return Column(
              children:
                  (snapshot.data ?? [])
                      .where(
                        (result) => !widget.isShowOnlyOnline || result.isOnline,
                      )
                      .map((result) => _tile(context, result))
                      .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, SearchResult result) {
    final channel = result.channel;
    final onChannelAdd = widget.onChannelAdd;
    final tile = _listTile(context, result);
    if (onChannelAdd == null || widget.channels.contains(channel)) {
      return tile;
    }
    final replaced = channelReplacedBy(widget.channels, channel);
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    // swiping right adds the result; it stays in the results.
    return Dismissible(
      key: ValueKey(channel.toString()),
      direction: DismissDirection.startToEnd,
      // adding isn't destructive, so it takes less of a swipe than removing.
      dismissThresholds: const {DismissDirection.startToEnd: 0.3},
      confirmDismiss: (direction) async {
        onChannelAdd(channel);
        return false;
      },
      background: Container(
        color: colors.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(
              replaced == null ? Icons.add : Icons.swap_horiz,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                replaced == null
                    ? l10n.addToChat
                    : l10n.replaceChannel(replaced.displayName),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
      child: tile,
    );
  }

  Widget _listTile(BuildContext context, SearchResult result) {
    final channel = result.channel;
    return ListTile(
      leading: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color:
                result.isOnline
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
                placeholder: result.image.placeholderImage,
                image: result.image,
                height: 48,
                width: 48,
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child:
                  result.isPromoted
                      ? Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        child: const Icon(
                          Icons.keyboard_double_arrow_up,
                          color: Colors.green,
                          size: 18.0,
                        ),
                      )
                      : Container(),
            ),
          ],
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ProviderIcon(result.provider, size: 14),
                ),
                Flexible(
                  child: Text(
                    result.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Text(
            result.language ?? "??",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
      subtitle: result.title == null ? null : Text(result.title!),
      onTap: () => widget.onChannelSelect(channel),
    );
  }
}
