import 'package:flutter/material.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote) onEmoteSelected;
  final Channel channel;
  static const _emoteColumns = 8;
  static const _footerHeight = 30;

  const EmotePickerWidget(
      {Key? key,
      required this.onEmoteSelected,
      required this.channel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rowNumber =
        MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 1.5;

    return SizedBox(
      height: (MediaQuery.of(context).size.width / _emoteColumns) * rowNumber +
          _footerHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FutureBuilder<List<Emote>>(
              future: getEmotes(channel),
              initialData: const [],
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return CustomScrollView(
                  shrinkWrap: true,
                  slivers: [
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: _emoteColumns),
                      delegate: SliverChildListDelegate.fixed(snapshot.data!
                          .map((emote) => IconButton(
                              tooltip: emote.code,
                              onPressed: () => onEmoteSelected(emote),
                              splashRadius: 24,
                              icon: Image(
                                  image: ResilientNetworkImage(emote.uri))))
                          .toList()),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
