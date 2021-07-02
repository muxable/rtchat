import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/scroll_view.dart';
import 'package:rtchat/models/chat_history.dart';

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
