import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/twitch/message.dart';
import 'package:rtchat/components/twitch/raid_event.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/user.dart';

class ChatPanelWidget extends StatefulWidget {
  final void Function(bool) onScrollback;

  ChatPanelWidget({Key? key, required this.onScrollback}) : super(key: key);

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
        widget.onScrollback(!_atBottom);
      }
    });
  }

  Widget cntTextStyle(cnt) {
    cnt = cnt.toString();
    return Text(cnt,
        style: TextStyle(color: Colors.deepPurpleAccent, fontSize: 20));
  }

  Widget cardInfoWidge(text, cnt) {
    return SizedBox(
      width: 100,
      height: 80,
      child: Card(
        color: Colors.white,
        child: Column(
          children: [
            cntTextStyle(0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChatHistoryModel>(builder: (context, model, child) {
        final messages = model.messages.reversed.toList();
        return ListView.builder(
          controller: _controller,
          padding: EdgeInsets.symmetric(vertical: 8),
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            if (message is TwitchMessageModel) {
              return InkWell(
                  onLongPress: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20.0))),
                              child: Wrap(
                                children: [
                                  ListView(
                                    shrinkWrap: true,
                                    children: [
                                      ListTile(
                                        shape: RoundedRectangleBorder(
                                            borderRadius: new BorderRadius.only(
                                          topLeft: const Radius.circular(20.0),
                                          topRight: const Radius.circular(20.0),
                                        )),
                                        leading: Icon(Icons.person,
                                            color: Colors.pinkAccent),
                                        title: Text('${message.author}',
                                            style: TextStyle(fontSize: 20)),
                                        tileColor: Colors.blueAccent,
                                        trailing: CloseButton(),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.favorite,
                                            color: Colors.deepPurpleAccent),
                                        title:
                                            Text('Following Since Jan 11 2024'),
                                      ),
                                      ListTile(
                                        leading: Icon(Icons.star,
                                            color: Colors.deepPurpleAccent),
                                        title: Text(
                                            'Sub Tier 3 - Since jan 11 2024'),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          cardInfoWidge('Messages', 0),
                                          cardInfoWidge('Timeouts', 0)
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          cardInfoWidge('Bans', 0),
                                          cardInfoWidge('Mod Messages', 0)
                                        ],
                                      ),
                                      ListTile(
                                          leading: Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          title: Text('Delete Message'),
                                          onTap: () {
                                            final model =
                                                Provider.of<UserModel>(context,
                                                    listen: false);
                                            model.delete(model.channels.first,
                                                message.messageId);
                                            Navigator.pop(context);
                                          }),
                                      ListTile(
                                          leading: Icon(Icons.timer_outlined,
                                              color: Colors.orangeAccent),
                                          title:
                                              Text('Timeout ${message.author}'),
                                          onTap: () {}),
                                      ListTile(
                                          leading: Icon(
                                              Icons.dnd_forwardslash_outlined,
                                              color: Colors.redAccent),
                                          title: Text('Ban ${message.author}'),
                                          onTap: () {}),
                                      ListTile(
                                          leading: Icon(Icons.circle_outlined,
                                              color: Colors.greenAccent),
                                          title:
                                              Text('Unban ${message.author}'),
                                          onTap: () {
                                            final model =
                                                Provider.of<UserModel>(context,
                                                    listen: false);
                                            model.unban(model.channels.first,
                                                message.author);
                                            Navigator.pop(context);
                                          }),
                                    ],
                                  )
                                ],
                              ));
                        });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TwitchMessageWidget(message),
                  ));
            } else if (message is TwitchRaidEventModel) {
              return TwitchRaidEventWidget(message);
            } else {
              throw new AssertionError("invalid message type");
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
