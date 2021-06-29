import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/sliver_floating_header.dart';
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
  void initState() {
    super.initState();

    _controller.addListener(() {
      final value =
          _controller.position.atEdge && _controller.position.pixels != 0;
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
        if (_atBottom) {
          WidgetsBinding.instance?.addPostFrameCallback((_) {
            _controller.jumpTo(_controller.position.maxScrollExtent);
          });
        }
        final messages = model.messages.toList();
        // construct slivers out of message chunks, using pinnable events as
        // delimiters.
        final slivers = <Widget>[];
        for (var i = 0; i < messages.length;) {
          final j = messages.indexWhere(
              (element) => element is PinnableMessageModel, i);
          final slice = (j > -1 ? messages.sublist(i, j) : messages.sublist(i));
          if (slice.isNotEmpty) {
            slivers.add(SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
              return ChatPanelMessageWidget(message: slice[index]);
            }, childCount: slice.length)));
          }
          if (j > -1) {
            slivers.add(SliverPinnableHeader(
                child: ChatPanelMessageWidget(message: messages[j])));
            i = j + 1;
          } else {
            break;
          }
        }
        return CustomScrollView(
          controller: _controller,
          slivers: slivers,
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
                _controller.animateTo(_controller.position.maxScrollExtent,
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
