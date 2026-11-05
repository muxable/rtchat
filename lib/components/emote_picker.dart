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
  final void Function(Emote) onEmoteSelected;
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

    // sort all channels alphabetically first.
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // ensure current channel emotes are first.
    final channelEmotesIndex = categories.indexOf(channel.displayName);
    if (channelEmotesIndex != -1) {
      categories.removeAt(channelEmotesIndex);
      categories.insert(0, channel.displayName);
    }

    // ensure global emotes are second, or first if the channel has no emotes.
    final globalEmotesIndex = categories.indexOf(globalEmotes);
    if (globalEmotesIndex != -1) {
      categories.removeAt(globalEmotesIndex);
      categories.insert(
        categories.isNotEmpty && categories.first == channel.displayName
            ? 1
            : 0,
        globalEmotes,
      );
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return StickyHeader(
          overlapHeaders: false,
          header: Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    byCategory[categories[index]]!.map((emote) {
                      return Tooltip(
                        message: emote.code,
                        preferBelow: false,
                        child: SizedBox(
                          width:
                              (MediaQuery.of(context).size.width - 32) /
                                  (MediaQuery.of(context).orientation ==
                                          Orientation.portrait
                                      ? 7
                                      : 13) -
                              8,
                          height: 36,
                          child: Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => onEmoteSelected(emote),
                              splashRadius: 24,
                              icon: CrossFadeImage(
                                placeholder: MemoryImage(kTransparentImage),
                                image: emote.image,
                                width: 36,
                                height: 36,
                              ),
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
  final void Function(Emote) onEmoteSelected;
  final Channel channel;

  @override
  Widget build(BuildContext context) {
    final byProvider = emotes.fold<Map<String, List<Emote>>>({}, (map, emote) {
      map.putIfAbsent(emote.provider, () => []).add(emote);
      return map;
    });

    final tabs = [
      if (byProvider.containsKey('twitch')) const Tab(text: 'Twitch'),
      if (byProvider.containsKey('bttv')) const Tab(text: 'BTTV'),
      if (byProvider.containsKey('ffz')) const Tab(text: 'FFZ'),
      if (byProvider.containsKey('7tv')) const Tab(text: '7TV'),
    ];

    if (tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(tabs: tabs),
          Expanded(
            child: TabBarView(
              children: [
                if (byProvider.containsKey('twitch'))
                  EmotesList(
                    emotes: byProvider['twitch']!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey('bttv'))
                  EmotesList(
                    emotes: byProvider['bttv']!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey('ffz'))
                  EmotesList(
                    emotes: byProvider['ffz']!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel,
                  ),
                if (byProvider.containsKey('7tv'))
                  EmotesList(
                    emotes: byProvider['7tv']!,
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
    final screenMaxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onEmoteSelected(null);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desiredHeight = 48.0 * rowNumber;
          final availableHeight =
              constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : screenMaxHeight;

          final pickerHeight = min(
            desiredHeight,
            min(screenMaxHeight, availableHeight),
          );

          return SizedBox(
            height: pickerHeight,
            child: _TabbedEmotePickerWidget(
              emotes: emotes,
              onEmoteSelected: (emote) => onEmoteSelected(emote),
              channel: channel,
            ),
          );
        },
      ),
    );
  }
}
