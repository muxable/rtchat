import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/messages.dart';

class MessageInputWidget extends StatefulWidget {
  final Channel channel;

  const MessageInputWidget({Key? key, required this.channel}) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final _textEditingController = TextEditingController();
  final _chatInputFocusNode = FocusNode();
  var _isEmotePickerVisible = false;

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
                    widget.channel, commandsModel.commandList[index].command);
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
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
            decoration: const InputDecoration(hintText: "Send a message..."),
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
        Consumer<MessagesModel>(builder: (context, messagesModel, child) {
          return IconButton(
              icon: Icon(messagesModel.isTtsEnabled
                  ? Icons.voice_over_off
                  : Icons.record_voice_over),
              onPressed: () {
                messagesModel.isTtsEnabled = !messagesModel.isTtsEnabled;
              });
        }),
      ]),
      _buildCommandBar(context),
      _isEmotePickerVisible ? _buildEmotePicker(context) : Container(),
    ]);
  }
}
