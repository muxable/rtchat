import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final _controller = ScrollController();
  var _atBottom = true;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final value =
          _controller.position.atEdge && _controller.position.pixels == 0;
      if (_atBottom != value) {
        setState(() {
          _atBottom = value;
        });
        if (widget.onScrollback != null) {
          widget.onScrollback!(!_atBottom);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChatHistoryModel>(builder: (context, model, child) {
        final messages = model.messages.reversed.toList();
        return ListView.builder(
          controller: _controller,
          padding: const EdgeInsets.symmetric(vertical: 8),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            if (message is TwitchMessageModel) {
              var coalesce = false;
              // the history is forward.
              if (index + 1 < messages.length) {
                final prev = messages[index + 1];
                coalesce =
                    prev is TwitchMessageModel && prev.author == message.author;
              }
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
                                    final userModel = Provider.of<UserModel>(
                                        context,
                                        listen: false);
                                    final channelsModel =
                                        Provider.of<ChannelsModel>(context,
                                            listen: false);
                                    userModel.delete(
                                        channelsModel.channels.first,
                                        message.messageId);
                                    Navigator.pop(context);
                                  }),
                              ListTile(
                                  title: Text('Timeout ${message.author}'),
                                  onTap: () {}),
                              ListTile(
                                  title: Text('Ban ${message.author}'),
                                  onTap: () {}),
                              ListTile(
                                  title: Text('Unban ${message.author}'),
                                  onTap: () {
                                    final userModel = Provider.of<UserModel>(
                                        context,
                                        listen: false);
                                    final channelsModel =
                                        Provider.of<ChannelsModel>(context,
                                            listen: false);
                                    userModel.unban(
                                        channelsModel.channels.first,
                                        message.author);
                                    Navigator.pop(context);
                                  }),
                            ]),
                          );
                        });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TwitchMessageWidget(message, coalesce: coalesce),
                  ));
            } else if (message is TwitchRaidEventModel) {
              return TwitchRaidEventWidget(message);
            } else {
              throw AssertionError("invalid message type");
            }
          },
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
