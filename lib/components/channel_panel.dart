import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';

class ChannelPanelWidget extends StatelessWidget {
  final _textEditingController = TextEditingController();
  final void Function(bool) onScrollback;
  final void Function(double) onResize;

  ChannelPanelWidget(
      {Key? key, required this.onScrollback, required this.onResize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModel>(builder: (context, layoutModel, child) {
      return Column(children: [
        // header
        Container(
          height: 56,
          child: Padding(
            padding: EdgeInsets.only(left: 16),
            child: Row(children: [
              Expanded(
                child: layoutModel.channels.isEmpty
                    ? Container()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                            Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Image(
                                  height: 24,
                                  image: AssetImage(
                                      'assets/providers/${layoutModel.channels.first.provider}.png')),
                            ),
                            Text("/${layoutModel.channels.first.displayName}",
                                overflow: TextOverflow.fade),
                          ]),
              ),
              layoutModel.locked
                  ? Container()
                  : GestureDetector(
                      onVerticalDragUpdate: (details) =>
                          onResize(details.delta.dy),
                      child: Icon(Icons.drag_handle),
                    ),
              Expanded(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  layoutModel.channels.isEmpty
                      ? Container()
                      : StatisticsBarWidget(
                          provider: layoutModel.channels.first.provider,
                          channelId: layoutModel.channels.first.channelId),
                  Consumer<ChatHistoryModel>(
                      builder: (context, chatHistoryModel, child) {
                    return IconButton(
                        icon: Icon(chatHistoryModel.ttsEnabled
                            ? Icons.record_voice_over
                            : Icons.voice_over_off),
                        tooltip: "Text to speech",
                        onPressed: () {
                          chatHistoryModel.ttsEnabled =
                              !chatHistoryModel.ttsEnabled;
                        });
                  }),
                ]),
              )
            ]),
          ),
        ),

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
                      model.send(layoutModel.channels.first, value);
                      _textEditingController.clear();
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.build, color: Colors.white),
                  onSelected: (value) async {
                    if (value == "Clear Chat") {
                      final channel = layoutModel.channels.first;
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
                ),
              ]),
            ),
          );
        })
      ]);
    });
  }
}
