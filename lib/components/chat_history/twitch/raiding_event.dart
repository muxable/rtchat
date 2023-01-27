import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/user.dart';

class TwitchRaidingEventWidget extends StatelessWidget {
  final TwitchRaidingEventModel model;

  const TwitchRaidingEventWidget(this.model, {Key? key}) : super(key: key);

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
                      child: Text.rich(TextSpan(
                        children: [
                          const TextSpan(text: "Raiding "),
                          TextSpan(
                              text: model.targetUser.displayName,
                              style: Theme.of(context).textTheme.titleSmall),
                          const TextSpan(text: "."),
                        ],
                      )),
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
                  child: Text.rich(TextSpan(
                    children: [
                      const TextSpan(text: "Raided "),
                      TextSpan(
                          text: model.targetUser.displayName,
                          style: Theme.of(context).textTheme.titleSmall),
                      const TextSpan(text: "."),
                    ],
                  )),
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
          child: Text.rich(TextSpan(
            children: [
              const TextSpan(text: "Raid to "),
              TextSpan(
                  text: model.targetUser.displayName,
                  style: Theme.of(context).textTheme.titleSmall),
              const TextSpan(text: " canceled."),
            ],
          )));
    }
  }
}
