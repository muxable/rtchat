import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/user.dart';
import 'package:styled_text/styled_text.dart';

class TwitchRaidingEventWidget extends StatelessWidget {
  final TwitchRaidingEventModel model;

  const TwitchRaidingEventWidget(this.model, {super.key});

  @override
  Widget build(BuildContext context) {
    if (!model.isComplete) {
      return StreamBuilder<int>(
          stream: Stream.periodic(const Duration(milliseconds: 500), (x) => x),
          builder: (context, snapshot) {
            final flash = snapshot.data == null || snapshot.data! % 2 == 0;
            final expiration = model.timestamp.add(model.duration);
            final remaining = expiration.difference(DateTime.now());
            return Stack(children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  color: flash
                      ? Theme.of(context).highlightColor
                      : Theme.of(context).colorScheme.secondary,
                ),
              ),
              DecoratedEventWidget.avatar(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  avatar:
                      ResilientNetworkImage(model.targetUser.profilePictureUrl),
                  child: Row(children: [
                    Expanded(
                      child: StyledText(
                        text: '<b>Raiding</b> ${model.targetUser.displayName}.',
                        tags: {
                          'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
                        },
                      ),
                    ),
                    Text.rich(TextSpan(
                        text: remaining.isNegative
                            ? "0s"
                            : "${remaining.inSeconds + 1}s",
                        style: Theme.of(context).textTheme.titleSmall))
                  ])),
            ]);
          });
    } else if (model.isSuccessful) {
      return GestureDetector(
          child: DecoratedEventWidget.avatar(
              avatar: ResilientNetworkImage(model.targetUser.profilePictureUrl),
              child: Row(children: [
                Expanded(
                  child: StyledText(
                    text: '<b>Raided</b> ${model.targetUser.displayName}.',
                    tags: {
                      'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
                    },
                  ),
                ),
                Text.rich(TextSpan(
                    text: "Join",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context)
                            .buttonTheme
                            .colorScheme
                            ?.primary))),
              ])),
          onTap: () {
            final userModel = Provider.of<UserModel>(context, listen: false);
            userModel.activeChannel = model.targetUser.asChannel;
          });
    } else {
      return DecoratedEventWidget.avatar(
          avatar: ResilientNetworkImage(model.targetUser.profilePictureUrl),
          child: StyledText(
            text: '<b>Raid to</b> ${model.targetUser.displayName} canceled.',
            tags: {
              'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
            },
          ));
    }
  }
}
