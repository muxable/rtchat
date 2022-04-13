import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_panel.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/commands.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class ChannelPanelWidget extends StatefulWidget {
  final void Function(bool)? onScrollback;
  final void Function()? onRequestExpand;
  final void Function(double)? onResize;
  final Channel channel;

  const ChannelPanelWidget(
      {Key? key,
      required this.channel,
      this.onScrollback,
      this.onResize,
      this.onRequestExpand})
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
        onDoubleTap: () {
          if (widget.onRequestExpand != null) {
            widget.onRequestExpand!();
          }
        },
        onVerticalDragStart: (details) {
          final layoutModel = Provider.of<LayoutModel>(context, listen: false);
          layoutModel.onDragStartHeight = layoutModel.panelHeight;
        },
        onVerticalDragEnd: (details) {
          final layoutModel = Provider.of<LayoutModel>(context, listen: false);
          layoutModel.dragEnd = true;
        },
        onVerticalDragUpdate: (details) {
          final layoutModel = Provider.of<LayoutModel>(context, listen: false);
          if (layoutModel.locked || widget.onResize == null) {
            return;
          }
          widget.onResize!(details.delta.dy);
        },
        child: Consumer<LayoutModel>(builder: (context, layoutModel, child) {
          if (layoutModel.locked) {
            return Container();
          }

          return const Center(
            child: SizedBox(
              width: 350,
              child: Icon(Icons.drag_handle_outlined),
            ),
          );
        }),
      ),
    );

    return Column(children: [
      // drag bar indicator,
      header,

      // body
      Expanded(
        child: ChatPanelWidget(onScrollback: widget.onScrollback),
      ),

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
                  if (value.startsWith('!')) {
                    final commandsModel =
                        Provider.of<CommandsModel>(context, listen: false);
                    commandsModel.addCommand(Command(value, DateTime.now()));
                  }
                  ActionsAdapter.instance.send(widget.channel, value);
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
            // Consumer<TtsModel>(builder: (context, ttsModel, child) {
            //   return IconButton(
            //     icon: Icon(ttsModel.enabled
            //         ? Icons.record_voice_over
            //         : Icons.voice_over_off),
            //     tooltip: "Text to speech",
            //     onPressed: () {
            //       ttsModel.enabled = !ttsModel.enabled;
            //     },
            //   );
            // }),
            _buildSendButton(),
          ]),
        );
      }),
      _buildCommandBar(context),
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
            ActionsAdapter.instance
                .send(widget.channel, text);
            _textEditingController.clear();
          })
      : Container();

  Widget _buildCommandBar(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Consumer<CommandsModel>(builder: (context, commandsModel, child) {
        if (!isKeyboardVisible || commandsModel.commandList.isEmpty) {
          return Container();
        }
        return SizedBox(
          height: 55,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: commandsModel.commandList.length,
            itemBuilder: (context, index) => TextButton(
              child: Text(commandsModel.commandList[index].command),
              onPressed: () {
                ActionsAdapter.instance.send(
                    widget.channel,
                    commandsModel.commandList[index].command);
                commandsModel.addCommand(Command(
                    commandsModel.commandList[index].command, DateTime.now()));
                _chatInputFocusNode.unfocus();
              },
            ),
          ),
        );
      });
    });
  }

  Widget _buildEmotePicker(BuildContext context) {
    return EmotePickerWidget(
        channelId: widget.channel.channelId,
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
        });
  }
}
