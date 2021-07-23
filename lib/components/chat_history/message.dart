import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/stream_state_event.dart';
import 'package:rtchat/components/chat_history/timeout_dialog.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/components/chat_history/twitch/raid_event.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/user.dart';

class ChatHistoryMessage extends StatelessWidget {
  final MessageModel message;

  const ChatHistoryMessage({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m is TwitchMessageModel) {
      return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        final child = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TwitchMessageWidget(m),
        );
        if (layoutModel.isInteractionLockable && layoutModel.locked) {
          return child;
        }
        return InkWell(
            onLongPress: () async {
              var showTimeoutDialog = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: ListView(shrinkWrap: true, children: [
                        ListTile(
                            title: const Text('Delete Message'),
                            onTap: () {
                              final userModel = Provider.of<UserModel>(context,
                                  listen: false);
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              userModel.delete(
                                  channelsModel.subscribedChannels.first,
                                  m.messageId);
                              Navigator.pop(context);
                            }),
                        ListTile(
                            title: Text('Timeout ${m.author.displayName}'),
                            onTap: () {
                              Navigator.pop(context, true);
                            }),
                        ListTile(
                            title: Text('Ban ${m.author.displayName}'),
                            onTap: () {
                              final userModel = Provider.of<UserModel>(context,
                                  listen: false);
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              userModel.ban(
                                  channelsModel.subscribedChannels.first,
                                  m.author.login,
                                  "banned by streamer");
                              Navigator.pop(context);
                            }),
                        ListTile(
                            title: Text('Unban ${m.author.displayName}'),
                            onTap: () {
                              final userModel = Provider.of<UserModel>(context,
                                  listen: false);
                              final channelsModel = Provider.of<ChannelsModel>(
                                  context,
                                  listen: false);
                              userModel.unban(
                                  channelsModel.subscribedChannels.first,
                                  m.author.login);
                              Navigator.pop(context);
                            }),
                      ]),
                    );
                  });
              if (showTimeoutDialog == true) {
                await showDialog(
                    context: context,
                    builder: (context) {
                      return TimeoutDialog(
                          title: "Timeout ${m.author.displayName}",
                          onPressed: (duration) {
                            final userModel =
                                Provider.of<UserModel>(context, listen: false);
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            userModel.timeout(
                                channelsModel.subscribedChannels.first,
                                m.author.login,
                                "timed out by streamer",
                                duration);
                            Navigator.pop(context);
                          });
                    });
              }
            },
            child: child);
      });
    } else if (m is TwitchRaidEventModel) {
      return TwitchRaidEventWidget(m);
    } else if (m is StreamStateEventModel) {
      return StreamStateEventWidget(m);
    } else {
      throw AssertionError("invalid message type");
    }
  }
}
