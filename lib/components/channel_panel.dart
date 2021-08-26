import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';

import 'channel_search_dialog.dart';

class _ChannelPickerValue {
  final Channel? channel;
  final bool isAdd;

  const _ChannelPickerValue({this.channel, this.isAdd = false});
}

class ChannelPanelWidget extends StatefulWidget {
  final void Function(bool)? onScrollback;
  final void Function(double)? onResize;

  const ChannelPanelWidget({Key? key, this.onScrollback, this.onResize})
      : super(key: key);

  @override
  _ChannelPanelWidgetState createState() => _ChannelPanelWidgetState();
}

class _ChannelPanelWidgetState extends State<ChannelPanelWidget> {
  final _textEditingController = TextEditingController();
  var _isEmotePickerVisible = false;
  final _chatInputFocusNode = FocusNode();

  @override
  void dispose() {
    _chatInputFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final header = Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final layoutModel = Provider.of<LayoutModel>(context, listen: false);
          if (layoutModel.locked || widget.onResize == null) {
            return;
          }
          widget.onResize!(details.delta.dy);
        },
        child: Row(children: [
          Consumer<LayoutModel>(builder: (context, layoutModel, child) {
            if (layoutModel.locked) {
              return Container();
            }
            return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.drag_indicator));
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
    );

    return Column(children: [
      // header
      DefaultTextStyle.merge(
          style: Theme.of(context).primaryTextTheme.subtitle2,
          child: IconTheme(
              data: Theme.of(context).primaryIconTheme,
              child: Container(
                  height: 56,
                  color: Theme.of(context).primaryColor,
                  child: header))),

      // body
      Expanded(child: ChatPanelWidget(onScrollback: widget.onScrollback)),

      // input
      Consumer<LayoutModel>(builder: (context, layoutModel, child) {
        if (layoutModel.isInteractionLockable && layoutModel.locked) {
          return Container();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            IconButton(
                onPressed: () {
                  if (_isEmotePickerVisible) {
                    setState(() => _isEmotePickerVisible = false);
                    _chatInputFocusNode.requestFocus();
                  } else {
                    _chatInputFocusNode.unfocus();
                    setState(() => _isEmotePickerVisible = true);
                  }
                },
                icon: Icon(_isEmotePickerVisible
                    ? Icons.keyboard_rounded
                    : Icons.tag_faces)),
            Expanded(
              child: TextField(
                focusNode: _chatInputFocusNode,
                controller: _textEditingController,
                textInputAction: TextInputAction.send,
                maxLines: null,
                decoration:
                    const InputDecoration(hintText: "Send a message..."),
                onChanged: (text) {
                  if (text[0] == '!') {
                    print("Command <${text}> detected.");
                  }
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
                  if (value[0] == '!') {
                    print("Command <${value}> sent.");
                  }
                  final channelsModel =
                      Provider.of<ChannelsModel>(context, listen: false);
                  ActionsAdapter.instance
                      .send(channelsModel.subscribedChannels.first, value);
                  _textEditingController.clear();
                },
                onTap: () => setState(() => _isEmotePickerVisible = false),
              ),
            ),
            // PopupMenuButton<String>(
            //   icon: const Icon(Icons.build),
            //   onSelected: (value) async {
            //     if (value == "Clear Chat") {
            //       FirebaseAnalytics().logEvent(name: "clear_chat");
            //       final channelsModel =
            //           Provider.of<ChannelsModel>(context, listen: false);
            //       final channel = channelsModel.subscribedChannels.first;
            //       FirebaseFunctions.instance.httpsCallable("clear")({
            //         "provider": channel.provider,
            //         "channelId": channel.channelId,
            //       });
            //     } else if (value == "Raid") {}
            //   },
            //   itemBuilder: (context) {
            //     final options = {'Clear Chat'};
            //     return options.map((String choice) {
            //       return PopupMenuItem<String>(
            //         value: choice,
            //         child: Text(choice),
            //       );
            //     }).toList();
            //   },
            // ),
            _buildSendButton(),
          ]),
        );
      }),
      _buildEmotePicker(context)
    ]);
  }

  Widget _buildSendButton() => _isEmotePickerVisible
      ? IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            var text = _textEditingController.text;
            if (text.isEmpty) {
              return;
            }
            final channelsModel =
                Provider.of<ChannelsModel>(context, listen: false);
            ActionsAdapter.instance
                .send(channelsModel.subscribedChannels.first, text);
            _textEditingController.clear();
          })
      : Container();

  Widget _buildEmotePicker(BuildContext context) {
    var channelProvider = Provider.of<ChannelsModel>(context, listen: false);
    return channelProvider.subscribedChannels.isNotEmpty &&
            _isEmotePickerVisible
        ? EmotePickerWidget(
            channelId: channelProvider.subscribedChannels.first.channelId,
            onDismiss: () => setState(() => _isEmotePickerVisible = false),
            onDelete: () {
              var initialText = _textEditingController.text;
              if (initialText.isNotEmpty) {
                _textEditingController.text =
                    initialText.substring(0, initialText.length - 1);
              }
            },
            onEmoteSelected: (emote) {
              _textEditingController.text =
                  _textEditingController.text + " " + emote.code;
            })
        : Container();
  }
}
