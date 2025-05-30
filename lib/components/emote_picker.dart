import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class EmotesList extends StatelessWidget {
  const EmotesList({
    super.key,
    required this.emotes,
    required this.onEmoteSelected,
    required this.channel,
  });

  final List<Emote> emotes;
  final Function(Emote) onEmoteSelected;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final globalEmotes = AppLocalizations.of(context)!.globalEmotes;
    final byCategory = emotes.fold<Map<String, List<Emote>>>({}, (map, emote) {
      final category = emote.category ?? globalEmotes;
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(emote);
      return map;
    });
    final categories = byCategory.keys.toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // ensure global emotes is first.
    final globalEmotesIndex = categories.indexOf(globalEmotes);
    if (globalEmotesIndex != -1) {
      categories.removeAt(globalEmotesIndex);
      categories.insert(0, globalEmotes);
    }

    // ensure channel emotes is second.
    final channelEmotesIndex = categories.indexOf(channel.displayName);
    if (channelEmotesIndex != -1) {
      categories.removeAt(channelEmotesIndex);
      categories.insert(1, channel.displayName);
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return StickyHeader(
          overlapHeaders: false,
          header: Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          content: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8.0,
                runSpacing: 8.0,
                children: byCategory[categories[index]]!.map((emote) {
                  return Tooltip(
                    message: emote.code,
                    preferBelow: false,
                    child: SizedBox(
                      // Adjust width for 7 emotes per row in portrait, 10 in landscape.
                      width: (MediaQuery.of(context).size.width - 32) /
                              (MediaQuery.of(context).orientation ==
                                      Orientation.portrait
                                  ? 7
                                  : 10) -
                          8,
                      height: 36,
                      child: IconButton(
                        onPressed: () => onEmoteSelected(emote),
                        splashRadius: 24,
                        icon: CrossFadeImage(
                          placeholder: emote.image.placeholderImage,
                          image: emote.image,
                          width: 36,
                          height: 36,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TabbedEmotePickerWidget extends StatelessWidget {
  const _TabbedEmotePickerWidget({
    required this.emotes,
    required this.onEmoteSelected,
    required this.channel,
  });

  final List<Emote> emotes;
  final Function(Emote) onEmoteSelected;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final byProvider = emotes.fold<Map<String, List<Emote>>>({}, (map, emote) {
      final provider = emote.provider;
      if (!map.containsKey(provider)) {
        map[provider] = [];
      }
      map[provider]!.add(emote);
      return map;
    });
    final tabs = [
      if (byProvider.containsKey("twitch")) const Tab(text: "Twitch"),
      if (byProvider.containsKey("bttv")) const Tab(text: "BTTV"),
      if (byProvider.containsKey("ffz")) const Tab(text: "FFZ"),
      if (byProvider.containsKey("7tv")) const Tab(text: "7TV"),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TabBar(tabs: tabs),
          Expanded(
            child: TabBarView(
              children: [
                if (byProvider.containsKey("twitch"))
                  EmotesList(
                    emotes: byProvider["twitch"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey("bttv"))
                  EmotesList(
                    emotes: byProvider["bttv"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey("ffz"))
                  EmotesList(
                    emotes: byProvider["ffz"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey("7tv"))
                  EmotesList(
                    emotes: byProvider["7tv"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote?) onEmoteSelected;
  final List<Emote> emotes;
  final Channel channel;

  const EmotePickerWidget({
    super.key,
    required this.onEmoteSelected,
    required this.channel,
    required this.emotes,
  });

  @override
  Widget build(BuildContext context) {
    final rowNumber =
        MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 4;
    final maxHeight = MediaQuery.of(context).size.height * 0.5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        onEmoteSelected(null);
      },
      child: SizedBox(
        height: min(48 * rowNumber.toDouble(), maxHeight),
        child: _TabbedEmotePickerWidget(
          emotes: emotes,
          onEmoteSelected: onEmoteSelected,
          channel: channel,
        ),
      ),
    );
  }
}
