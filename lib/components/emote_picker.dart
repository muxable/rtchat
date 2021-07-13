import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/twitch/emote.dart';

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote) onEmoteSelected;
  final void Function() onDelete;
  final void Function() onDismiss;
  final String channelId;

  const EmotePickerWidget(
      {Key? key,
      required this.onEmoteSelected,
      required this.onDelete,
      required this.onDismiss,
      required this.channelId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 290.0,
      child: Column(children: <Widget>[
        Consumer<TwitchEmoteSets>(
          builder: (context, model, child) {
            final emotes = model.emotes[channelId] ?? [];
            return Flexible(
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8),
                    delegate: SliverChildListDelegate.fixed(emotes
                        .map((emote) => IconButton(
                            onPressed: () => onEmoteSelected(emote),
                            icon: Image(image: NetworkImage(emote.source))))
                        .toList()),
                  ),
                ],
              ),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                padding: const EdgeInsets.only(left: 16),
                icon: const Icon(Icons.close),
                tooltip: "Close",
                onPressed: onDismiss),
            IconButton(
                padding: const EdgeInsets.only(right: 16),
                icon: const Icon(Icons.backspace),
                tooltip: "Delete",
                onPressed: onDelete)
          ],
        )
      ]),
    );
  }
}
