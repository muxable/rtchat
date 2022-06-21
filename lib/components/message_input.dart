import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';

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

  sendMessage(String value) async {
    value = value.trim();
    if (value.isEmpty) {
      return;
    }
    if (value.startsWith('!')) {
      final commandsModel = Provider.of<CommandsModel>(context, listen: false);
      commandsModel.addCommand(Command(value, DateTime.now()));
    }
    ActionsAdapter.instance.send(widget.channel, value);
    _textEditingController.clear();
  }

  Widget _buildCommandBar(BuildContext context) {
    return KeyboardVisibilityBuilder(builder: (context, isKeyboardVisible) {
      return Consumer<CommandsModel>(builder: (context, commandsModel, child) {
        if (!isKeyboardVisible || commandsModel.commandList.isEmpty) {
          return Container();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: commandsModel.commandList.length,
              itemBuilder: (context, index) => TextButton(
                child: Text(commandsModel.commandList[index].command),
                onPressed: () {
                  ActionsAdapter.instance.send(
                      widget.channel, commandsModel.commandList[index].command);
                  commandsModel.addCommand(Command(
                      commandsModel.commandList[index].command,
                      DateTime.now()));
                  _chatInputFocusNode.unfocus();
                },
              ),
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
              "${_textEditingController.text} ${emote.code}";
        });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                color: Theme.of(context).inputDecorationTheme.fillColor),
            child: Row(children: [
              Expanded(
                child: TextField(
                  focusNode: _chatInputFocusNode,
                  controller: _textEditingController,
                  textInputAction: TextInputAction.send,
                  maxLines: 6,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                      prefixIcon: Material(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(24),
                        child: IconButton(
                            color: Theme.of(context).colorScheme.onSurface,
                            onPressed: () {
                              if (_isEmotePickerVisible) {
                                setState(() => _isEmotePickerVisible = false);
                                _chatInputFocusNode.requestFocus();
                              } else {
                                _chatInputFocusNode.unfocus();
                                setState(() => _isEmotePickerVisible = true);
                              }
                            },
                            splashRadius: 24,
                            icon: Icon(_isEmotePickerVisible
                                ? Icons.keyboard_rounded
                                : Icons.tag_faces_rounded)),
                      ),
                      suffixIcon: Material(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(24),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded),
                          color: Theme.of(context).colorScheme.primary,
                          splashRadius: 24,
                          onPressed: () =>
                              sendMessage(_textEditingController.text),
                        ),
                      ),
                      border: InputBorder.none,
                      hintText: "Send a message..."),
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
                  onSubmitted: sendMessage,
                  onTap: () => setState(() => _isEmotePickerVisible = false),
                ),
              ),
            ]),
          ),
        ),
        _buildCommandBar(context),
        _isEmotePickerVisible ? _buildEmotePicker(context) : Container(),
      ]),
    );
  }
}
