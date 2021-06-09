import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/twitch/message.dart';
import 'package:rtchat/components/twitch/raid_event.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/user.dart';

class ChannelPanelWidget extends StatelessWidget {
  final _textEditingController = TextEditingController();
  final void Function(bool) onScrollback;
  final void Function(int) onResize;

  ChannelPanelWidget(
      {Key? key, required this.onScrollback, required this.onResize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      return Column(children: [
        // header

        // body
        Expanded(child: ChatPanelWidget(onScrollback: onScrollback)),

        // input
        Builder(builder: (context) {
          if (layoutModel.isInputLockable && layoutModel.locked) {
            return Container();
          }
          return Container(
            color: Theme.of(context).primaryColor,
            child: SafeArea(
              top: false,
              bottom: true,
              left: false,
              right: false,
              minimum: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    textInputAction: TextInputAction.send,
                    maxLines: null,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Send a message...",
                        hintStyle: TextStyle(color: Colors.white),
                        border: InputBorder.none),
                    onChanged: (text) {
                      final filtered = text.replaceAll('\n', ' ');
                      if (filtered == text) {
                        return;
                      }
                      _textEditingController.value = TextEditingValue(
                          text: filtered,
                          selection: TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController.text.length)));
                    },
                    onSubmitted: (value) async {
                      value = value.trim();
                      if (value.isEmpty) {
                        return;
                      }
                      final model =
                          Provider.of<UserModel>(context, listen: false);
                      model.send(model.channels.first, value);
                      _textEditingController.clear();
                    },
                  ),
                ),
                Consumer<UserModel>(builder: (context, userModel, child) {
                  return PopupMenuButton<String>(
                    icon: Icon(Icons.build, color: Colors.white),
                    onSelected: (value) async {
                      if (value == "Clear Chat") {
                        final channel = userModel.channels.first;
                        FirebaseFunctions.instance.httpsCallable("clear")({
                          "provider": channel.provider,
                          "channelId": channel.channelId,
                        });
                        Provider.of<ChatHistoryModel>(context, listen: false)
                            .clear();
                      } else if (value == "Raid") {}
                    },
                    itemBuilder: (context) {
                      final options = {'Clear Chat'};
                      return options.map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      }).toList();
                    },
                  );
                }),
              ]),
            ),
          );
        })
      ]);
    });
  }
}
