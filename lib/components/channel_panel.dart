import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

import 'channel_search_dialog.dart';

class _ChannelPickerValue {
  final Channel? channel;
  final bool isAdd;

  const _ChannelPickerValue({this.channel, this.isAdd = false});
}

class ChannelPanelWidget extends StatelessWidget {
  final _textEditingController = TextEditingController();
  final void Function(bool)? onScrollback;
  final void Function(double)? onResize;

  ChannelPanelWidget({Key? key, this.onScrollback, this.onResize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final header = DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Container(
        height: 56,
        color: Theme.of(context).primaryColor,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(children: [
            Consumer<LayoutModel>(builder: (context, layoutModel, child) {
              if (layoutModel.locked || onResize == null) {
                return Container();
              }
              return GestureDetector(
                onVerticalDragUpdate: (details) => onResize!(details.delta.dy),
                child: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.drag_indicator)),
              );
            }),
            Consumer<ChannelsModel>(builder: (context, channelsModel, child) {
              if (channelsModel.subscribedChannels.isEmpty) {
                return const Spacer();
              }
              final first = channelsModel.subscribedChannels.first;
              return Expanded(
                child: PopupMenuButton<_ChannelPickerValue>(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image(
                                height: 24,
                                image: AssetImage(
                                    'assets/providers/${first.provider}.png')),
                          ),
                          Expanded(
                            child: Text("/${first.displayName}",
                                softWrap: false, overflow: TextOverflow.fade),
                          ),
                        ]),
                    onSelected: (value) async {
                      if (value.isAdd) {
                        // show the search dialog.
                        await showDialog(
                          context: context,
                          builder: (context) =>
                              ChannelSearchDialog(onSelect: (channel) {
                            channelsModel.subscribedChannels = {channel};
                            Navigator.pop(context);
                          }),
                        );
                      } else {
                        channelsModel.subscribedChannels = {value.channel!};
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        ...channelsModel.availableChannels.map((channel) {
                          return PopupMenuItem(
                              value: _ChannelPickerValue(channel: channel),
                              child: ListTile(
                                title: Text(channel.displayName),
                              ));
                        }),
                        const PopupMenuItem(
                            value: _ChannelPickerValue(isAdd: true),
                            child: ListTile(
                                title: Text("Find a channel"),
                                leading: Icon(Icons.add)))
                      ];
                    }),
              );
            }),
            Consumer<ChannelsModel>(builder: (context, channelsModel, child) {
              if (channelsModel.subscribedChannels.isEmpty) {
                return Container();
              }
              final first = channelsModel.subscribedChannels.first;
              return StatisticsBarWidget(
                  provider: first.provider, channelId: first.channelId);
            }),
            Consumer<TtsModel>(builder: (context, ttsModel, child) {
              return IconButton(
                  icon: Icon(ttsModel.enabled
                      ? Icons.record_voice_over
                      : Icons.voice_over_off),
                  tooltip: "Text to speech",
                  onPressed: () {
                    ttsModel.enabled = !ttsModel.enabled;
                  });
            }),
          ]),
        ),
      ),
    );

    return Column(children: [
      // header
      header,
      // body
      Expanded(child: ChatPanelWidget(onScrollback: onScrollback)),

      // input
      Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        if (layoutModel.isInteractionLockable && layoutModel.locked) {
          return Container();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _textEditingController,
                textInputAction: TextInputAction.send,
                maxLines: null,
                decoration:
                    const InputDecoration(hintText: "Send a message..."),
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
                  final userModel =
                      Provider.of<UserModel>(context, listen: false);
                  final channelsModel =
                      Provider.of<ChannelsModel>(context, listen: false);
                  userModel.send(channelsModel.subscribedChannels.first, value);
                  _textEditingController.clear();
                },
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.build),
              onSelected: (value) async {
                if (value == "Clear Chat") {
                  FirebaseAnalytics().logEvent(name: "clear_chat");
                  final channelsModel =
                      Provider.of<ChannelsModel>(context, listen: false);
                  final channel = channelsModel.subscribedChannels.first;
                  FirebaseFunctions.instance.httpsCallable("clear")({
                    "provider": channel.provider,
                    "channelId": channel.channelId,
                  });
                  Provider.of<ChatHistoryModel>(context, listen: false).clear();
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
        );
      })
    ]);
  }
}
