import 'package:flutter/material.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

class EmotesList extends StatelessWidget {
  const EmotesList(
      {Key? key, required this.emotes, required this.onEmoteSelected})
      : super(key: key);

  final List<Emote> emotes;
  final Function(Emote) onEmoteSelected;

  @override
  Widget build(BuildContext context) {
    final byCategory = emotes.fold<Map<String, List<Emote>>>({}, (map, emote) {
      final category = emote.category ?? "Global Emotes";
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(emote);
      return map;
    });
    final categories = byCategory.keys.toList();
    categories.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    // ensure global emotes is first.
    final globalEmotesIndex = categories.indexOf("Global Emotes");
    if (globalEmotesIndex != -1) {
      categories.removeAt(globalEmotesIndex);
      categories.insert(0, "Global Emotes");
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
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                        icon: FadeInImage(
                            placeholder: MemoryImage(kTransparentImage),
                            image: ResilientNetworkImage(emote.uri))));
              }).toList(),
            )),
          );
        });
  }
}

class EmotePickerWidget extends StatefulWidget {
  final void Function(Emote?) onEmoteSelected;
  final Channel channel;
  static const _footerHeight = 30;

  const EmotePickerWidget(
      {Key? key, required this.onEmoteSelected, required this.channel})
      : super(key: key);

  @override
  State<EmotePickerWidget> createState() => _EmotePickerWidgetState();
}

class _EmotePickerWidgetState extends State<EmotePickerWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Emote>> _emotesFuture;

  @override
  void initState() {
    super.initState();
    _emotesFuture = getEmotes(widget.channel);
    _emotesFuture.then((e) {
      _tabController = TabController(
          length: e.map((e) => e.provider).toSet().length, vsync: this);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rowNumber =
        MediaQuery.of(context).orientation == Orientation.portrait ? 5 : 3;

    return WillPopScope(
      onWillPop: () async {
        widget.onEmoteSelected(null);
        return false;
      },
      child: SizedBox(
        height: 48 * rowNumber.toDouble() + EmotePickerWidget._footerHeight,
        child: FutureBuilder<List<Emote>>(
            future: _emotesFuture,
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final byProvider = snapshot.data
                      ?.fold<Map<String, List<Emote>>>({}, (map, emote) {
                    final provider = emote.provider;
                    if (!map.containsKey(provider)) {
                      map[provider] = [];
                    }
                    map[provider]!.add(emote);
                    return map;
                  }) ??
                  {};
              return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        if (byProvider.containsKey("twitch"))
                          const Tab(text: "Twitch"),
                        if (byProvider.containsKey("bttv"))
                          const Tab(text: "BTTV"),
                        if (byProvider.containsKey("ffz"))
                          const Tab(text: "FFZ"),
                        if (byProvider.containsKey("7tv"))
                          const Tab(text: "7TV"),
                      ],
                    ),
                    Expanded(
                        child: TabBarView(
                      controller: _tabController,
                      children: [
                        if (byProvider.containsKey("twitch"))
                          EmotesList(
                              emotes: byProvider["twitch"]!,
                              onEmoteSelected: widget.onEmoteSelected),
                        if (byProvider.containsKey("bttv"))
                          EmotesList(
                              emotes: byProvider["bttv"]!,
                              onEmoteSelected: widget.onEmoteSelected),
                        if (byProvider.containsKey("ffz"))
                          EmotesList(
                              emotes: byProvider["ffz"]!,
                              onEmoteSelected: widget.onEmoteSelected),
                        if (byProvider.containsKey("7tv"))
                          EmotesList(
                              emotes: byProvider["7tv"]!,
                              onEmoteSelected: widget.onEmoteSelected),
                      ],
                    )),
                  ]);
            }),
      ),
    );
  }
}
