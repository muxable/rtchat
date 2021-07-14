import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/statistics_bar.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

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
    return Consumer<ChannelsModel>(builder: (context, channelsModel, child) {
      final header = DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: Container(
          height: 56,
          color: Theme.of(context).primaryColor,
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(children: [
              Consumer<LayoutModel>(builder: (context, layoutModel, child) {
                if (layoutModel.locked || widget.onResize == null) {
                  return Container();
                }
                return GestureDetector(
                  onVerticalDragUpdate: (details) =>
                      widget.onResize!(details.delta.dy),
                  child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(Icons.drag_indicator)),
                );
              }),
              if (channelsModel.channels.isEmpty)
                Container()
              else
                Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image(
                              height: 24,
                              image: AssetImage(
                                  'assets/providers/${channelsModel.channels.first.provider}.png')),
                        ),
                        Expanded(
                          child: Text(
                              "/${channelsModel.channels.first.displayName}",
                              softWrap: false,
                              overflow: TextOverflow.fade),
                        ),
                      ]),
                ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                channelsModel.channels.isEmpty
                    ? Container()
                    : StatisticsBarWidget(
                        provider: channelsModel.channels.first.provider,
                        channelId: channelsModel.channels.first.channelId),
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
            ]),
          ),
        ),
      );

      return Column(children: [
        // header
        header,
        // body
        Expanded(child: ChatPanelWidget(onScrollback: widget.onScrollback)),

        // input
        Consumer<LayoutModel>(builder: (context, layoutModel, child) {
          if (layoutModel.isInputLockable && layoutModel.locked) {
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
                    userModel.send(channelsModel.channels.first, value);
                    _textEditingController.clear();
                  },
                  onTap: () => setState(() => _isEmotePickerVisible = false),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.build),
                onSelected: (value) async {
                  if (value == "Clear Chat") {
                    final channelsModel =
                        Provider.of<ChannelsModel>(context, listen: false);
                    final channel = channelsModel.channels.first;
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
              _buildSendButton(),
            ]),
          );
        }),
        _buildEmotePicker(context)
      ]);
    });
  }

  Widget _buildSendButton() => _isEmotePickerVisible
      ? IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            var text = _textEditingController.text;
            if (text.isEmpty) {
              return;
            }
            final userModel = Provider.of<UserModel>(context, listen: false);
            final channelsModel =
                Provider.of<ChannelsModel>(context, listen: false);
            userModel.send(channelsModel.channels.first, text);
            _textEditingController.clear();
          })
      : Container();

  Widget _buildEmotePicker(BuildContext context) {
    var channelProvider = Provider.of<ChannelsModel>(context, listen: false);
    return channelProvider.channels.isNotEmpty
        ? Offstage(
            child: EmotePickerWidget(
                channelId: channelProvider.channels.first.channelId,
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
                }),
            offstage: !_isEmotePickerVisible)
        : Container();
  }
}
