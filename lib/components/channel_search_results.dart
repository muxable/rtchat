import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/l10n/app_localizations.dart';
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
        login: data['login'],
        displayName: data['displayName'],
        isOnline: data['onlineAt'] != null,
        imageUrl: Uri.parse(
            "https://rtirl.com/pfp.png?provider=$provider&channelId=$channelId"),
        title: title,
        language: data['language'],
        isPromoted: true);
  }).toList();
}

// The providers channel search can target, with the prefix shown for each.
const searchProviders = {"twitch": "twitch.tv/", "kick": "kick.com/"};

typedef ChannelSearch = Stream<List<SearchResult>> Function(
    String query, String provider, bool isShowOnlyOnline);

// Recently active channels for [provider] matching [query], online first.
List<SearchResult> filterRecentChannels(
    List<SearchResult> results, String query, String provider) {
  final needle = query.toLowerCase();
  final matches = results.where((result) =>
      result.provider == provider &&
      (result.displayName.toLowerCase().contains(needle) ||
          result.login.toLowerCase().contains(needle)));
  return [
    ...matches.where((element) => element.isOnline),
    ...matches.where((element) => !element.isOnline)
  ].take(5).toList();
}

Stream<List<SearchResult>> searchChannels(
    String query, String provider, bool isShowOnlyOnline) async* {
  final fastRanked = filterRecentChannels(await fastSearch(), query, provider);
  yield fastRanked;
  final slow =
      await _search({"query": query, "provider": provider}).then((result) {
    return (result.data as List<dynamic>)
        .map((data) => SearchResult(
            channelId: data['channelId'],
            provider: data['provider'],
            login: data['login'],
            displayName: data['displayName'],
            isOnline: data['isOnline'],
            imageUrl: Uri.parse(data['imageUrl']),
            title: data['title'],
            language: data['language'],
            isPromoted: false))
        .toList();
  });
  final slowFiltered = slow.where((result) =>
      result.provider == provider &&
      !fastRanked.any((element) => element.channelId == result.channelId) &&
      (!isShowOnlyOnline || result.isOnline));
  yield [...fastRanked, ...slowFiltered];
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

  const SearchResult(
      {required this.channelId,
      required this.provider,
      required this.login,
      required this.displayName,
      required this.isOnline,
      required this.imageUrl,
      required this.title,
      required this.isPromoted,
      required this.language});

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

  /// Adds a result to the channels shown, from a button on each result. No
  /// button without it.
  final void Function(Channel)? onChannelAdd;

  /// Whether a result was already added, which disables its add button.
  final bool Function(Channel)? isAdded;

  /// Shown above the results, scrolling with them.
  final Widget? header;

  const ChannelSearchResultsWidget(
      {super.key,
      required this.query,
      this.provider = "twitch",
      this.search = searchChannels,
      required this.onChannelSelect,
      required this.isShowOnlyOnline,
      this.controller,
      this.onChannelAdd,
      this.isAdded,
      this.header});

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
    _results =
        widget.search(widget.query, widget.provider, widget.isShowOnlyOnline);
  }

  @override
  void didUpdateWidget(covariant ChannelSearchResultsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      // switching provider searches right away.
      _debounce?.cancel();
      _results =
          widget.search(widget.query, widget.provider, widget.isShowOnlyOnline);
    } else if (oldWidget.query != widget.query ||
        oldWidget.isShowOnlyOnline != widget.isShowOnlyOnline) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _results = widget.search(
              widget.query, widget.provider, widget.isShowOnlyOnline);
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
              children: (snapshot.data ?? [])
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
    final isAdded = widget.isAdded?.call(channel) ?? false;
    return ListTile(
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
                        placeholder: result.image.placeholderImage,
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
                                color: Theme.of(context).colorScheme.tertiary,
                                borderRadius: BorderRadius.circular(18.0),
                              ),
                              child: const Icon(
                                Icons.keyboard_double_arrow_up,
                                color: Colors.green,
                                size: 18.0,
                              ),
                            )
                          : Container())
                ])),
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ProviderIcon(result.provider, size: 14),
              ),
              Flexible(
                child:
                    Text(result.displayName, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
          Text(
            result.language ?? "??",
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ]),
        subtitle: result.title == null ? null : Text(result.title!),
        trailing: onChannelAdd == null
            ? null
            : IconButton(
                tooltip: AppLocalizations.of(context)!.addToChat,
                icon: Icon(isAdded ? Icons.check : Icons.add),
                onPressed: isAdded ? null : () => onChannelAdd(channel),
              ),
        onTap: () => widget.onChannelSelect(channel));
  }
}
