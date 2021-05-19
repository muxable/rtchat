import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/messages/twitch_message.dart';
import 'package:rtchat/models/chat_history.dart';

class ChatPanelWidget extends StatefulWidget {
  ChatPanelWidget({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _ChatPanelWidgetState createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget> {
  var _controller = ScrollController();
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
          padding: EdgeInsets.all(16),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return TwitchMessageWidget(
                color: message.tags['color'],
                type: message.tags['message-type'],
                author: message.author,
                message: message.message,
                emotes: message.tags['emotes-raw']);
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
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Colors.black.withOpacity(0.6)),
                padding: MaterialStateProperty.all(
                    EdgeInsets.only(left: 16, right: 16)),
              ),
              child: Text("Scroll to bottom")),
        );
      }),
    ]);
  }
}
