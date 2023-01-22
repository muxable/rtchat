import 'package:flutter/material.dart';
import 'package:rtchat/components/image/cross_fade_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class EmotesList extends StatelessWidget {
  const EmotesList({
    Key? key,
    required this.emotes,
    required this.onEmoteSelected,
    required this.channel,
  }) : super(key: key);

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
        itemCount: byCategory.length,
        itemBuilder: (context, index) {
          return StickyHeader(
            header: Container(
              color: Theme.of(context).secondaryHeaderColor,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    categories[index],
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
                  )),
            ),
            content: Center(
                child: Wrap(
              children: byCategory[categories[index]]!.map((emote) {
                return Tooltip(
                    message: emote.code,
                    preferBelow: false,
                    child: IconButton(
                        onPressed: () => onEmoteSelected(emote),
                        splashRadius: 24,
                        icon: CrossFadeImage(
                            placeholder: emote.image.placeholderImage,
                            image: emote.image)));
              }).toList(),
            )),
          );
        });
  }
}

class _TabbedEmotePickerWidget extends StatelessWidget {
  const _TabbedEmotePickerWidget({
    Key? key,
    required this.emotes,
    required this.onEmoteSelected,
    required this.channel,
  }) : super(key: key);

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
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          TabBar(tabs: tabs),
          Expanded(
              child: TabBarView(
            children: [
              if (byProvider.containsKey("twitch"))
                EmotesList(
                    emotes: byProvider["twitch"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel),
              if (byProvider.containsKey("bttv"))
                EmotesList(
                    emotes: byProvider["bttv"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel),
              if (byProvider.containsKey("ffz"))
                EmotesList(
                    emotes: byProvider["ffz"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel),
              if (byProvider.containsKey("7tv"))
                EmotesList(
                    emotes: byProvider["7tv"]!,
                    onEmoteSelected: onEmoteSelected,
                    channel: channel),
            ],
          )),
        ]));
  }
}

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote?) onEmoteSelected;
  final Channel channel;

  const EmotePickerWidget(
      {Key? key, required this.onEmoteSelected, required this.channel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rowNumber =
        MediaQuery.of(context).orientation == Orientation.portrait ? 6 : 4;

    return WillPopScope(
      onWillPop: () async {
        onEmoteSelected(null);
        return false;
      },
      child: SizedBox(
        height: 48 * rowNumber.toDouble(),
        child: FutureBuilder<List<Emote>>(
            future: getEmotes(channel),
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              return _TabbedEmotePickerWidget(
                  emotes: snapshot.data!,
                  onEmoteSelected: onEmoteSelected,
                  channel: channel);
            }),
      ),
    );
  }
}
