import 'package:flutter/material.dart';
import 'package:flutter_image/flutter_image.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote) onEmoteSelected;
  final void Function() onDelete;
  final void Function() onDismiss;
  final String channelId;
  static const _emoteColumns = 8;
  static const _footerHeight = 30;

  const EmotePickerWidget(
      {Key? key,
      required this.onEmoteSelected,
      required this.onDelete,
      required this.onDismiss,
      required this.channelId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _rowNumber =
        MediaQuery.of(context).orientation == Orientation.portrait ? 3 : 1.5;

    return SizedBox(
      height: (MediaQuery.of(context).size.width / _emoteColumns) * _rowNumber +
          _footerHeight,
      child: Column(children: <Widget>[
        FutureBuilder<List<Emote>>(
          future: getTwitchEmotes(channelId),
          initialData: const [],
          builder: (context, snapshot) {
            return Flexible(
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: <Widget>[
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _emoteColumns),
                    delegate: SliverChildListDelegate.fixed(snapshot.data!
                        .map((emote) => IconButton(
                            onPressed: () => onEmoteSelected(emote),
                            icon: Image(
                                image: NetworkImageWithRetry(
                                    emote.source.toString()))))
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
