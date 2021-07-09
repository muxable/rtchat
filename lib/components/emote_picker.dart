import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/twitch/emote.dart';

class EmotePickerWidget extends StatelessWidget {
  final void Function(Emote)? onEmoteSelected;
  final String channelId;
  final double height = 290.0;

  const EmotePickerWidget(
      {Key? key, required this.onEmoteSelected, required this.channelId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Consumer<TwitchEmoteSets>(
        builder: (context, model, child) {
          final emotes = model.emotes[channelId] ?? [];
          return CustomScrollView(
            shrinkWrap: true,
            slivers: <Widget>[
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8),
                delegate: SliverChildListDelegate.fixed(emotes
                    .map((emote) => IconButton(
                        onPressed: () => onEmoteSelected!(emote),
                        icon: Image(image: NetworkImage(emote.source))))
                    .toList()),
              ),
            ],
          );
        },
      ),
    );
  }
}
