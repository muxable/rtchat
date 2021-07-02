import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history_render_box.dart';
import 'package:rtchat/components/twitch/message.dart';
import 'package:rtchat/components/twitch/raid_event.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/user.dart';

class ChatPanelWidget extends StatefulWidget {
  final void Function(bool)? onScrollback;

  const ChatPanelWidget({Key? key, this.onScrollback}) : super(key: key);

  @override
  _ChatPanelWidgetState createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget> {
  final _controller = ScrollController(keepScrollOffset: true);
  var _atBottom = true;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChatHistoryModel>(builder: (context, model, child) {
        final messages = model.messages.reversed.toList();
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final value =
                notification.metrics.atEdge && notification.metrics.pixels == 0;
            if (_atBottom != value) {
              setState(() {
                _atBottom = value;
              });
              if (widget.onScrollback != null) {
                widget.onScrollback!(!_atBottom);
              }
            }
            return false;
          },
          child: PinnableMessageScrollView(
            controller: _controller,
            reverse: true,
            messages: messages,
          ),
        );
      }),
      Builder(builder: (context) {
        if (_atBottom) {
          return Container();
        }
        return Container(
          alignment: Alignment.bottomCenter,
          child: TextButton(
              onPressed: () {
                _controller.animateTo(0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Colors.black.withOpacity(0.6)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 16, right: 16)),
              ),
              child: const Text("Scroll to bottom")),
        );
      }),
    ]);
  }
}

class ChatPanelMessageWidget extends StatelessWidget {
  final MessageModel message;

  const ChatPanelMessageWidget({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final m = message;
    if (m is TwitchMessageModel) {
      var coalesce = false;
      // the history is forward.
      // if (index + 1 < messages.length) {
      //   final prev = messages[index + 1];
      //   coalesce = prev is TwitchMessageModel && prev.author == message.author;
      // }
      return InkWell(
          onLongPress: () {
            showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: ListView(shrinkWrap: true, children: [
                      ListTile(
                          title: const Text('Delete Message'),
                          onTap: () {
                            final userModel =
                                Provider.of<UserModel>(context, listen: false);
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            userModel.delete(
                                channelsModel.channels.first, m.messageId);
                            Navigator.pop(context);
                          }),
                      ListTile(
                          title: Text('Timeout ${m.author}'), onTap: () {}),
                      ListTile(title: Text('Ban ${m.author}'), onTap: () {}),
                      ListTile(
                          title: Text('Unban ${m.author}'),
                          onTap: () {
                            final userModel =
                                Provider.of<UserModel>(context, listen: false);
                            final channelsModel = Provider.of<ChannelsModel>(
                                context,
                                listen: false);
                            userModel.unban(
                                channelsModel.channels.first, m.author);
                            Navigator.pop(context);
                          }),
                    ]),
                  );
                });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TwitchMessageWidget(m, coalesce: coalesce),
          ));
    } else if (m is TwitchRaidEventModel) {
      return TwitchRaidEventWidget(m);
    } else {
      throw AssertionError("invalid message type");
    }
  }
}
