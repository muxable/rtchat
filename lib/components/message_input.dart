import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_mode.dart';
import 'package:rtchat/models/commands.dart';

class MessageInputWidget extends StatefulWidget {
  final Channel channel;

  const MessageInputWidget({Key? key, required this.channel}) : super(key: key);

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

final _emotes = [
  "https://static-cdn.jtvnw.net/emoticons/v2/425618/default/light/2.0",
  "https://static-cdn.jtvnw.net/emoticons/v2/112291/default/light/2.0",
  "https://static-cdn.jtvnw.net/emoticons/v2/81274/default/light/2.0",
  "https://static-cdn.jtvnw.net/emoticons/v2/28087/default/light/2.0",
  "https://static-cdn.jtvnw.net/emoticons/v2/305954156/default/light/2.0",
];

const _greyscale = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, // red
  0.2126, 0.7152, 0.0722, 0, 0, // green
  0.2126, 0.7152, 0.0722, 0, 0, // blue
  0, 0, 0, 1, 0, // alpha
]);

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final _textEditingController = TextEditingController();
  final _chatInputFocusNode = FocusNode();
  var _isEmotePickerVisible = false;
  var _isTextCommand = false;
  var _isKeyboardVisible = false;
  late StreamSubscription keyboardSubscription;
  var _emoteIndex = Random().nextInt(_emotes.length);

  @override
  void initState() {
    super.initState();
    final keyboardVisibilityController = KeyboardVisibilityController();
    // Subscribe to keyboard visibility changes.
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((visible) {
      setState(() {
        _isKeyboardVisible = visible;
      });
    });
    // Subscribe to text editing changes.
    _textEditingController.addListener(() {
      setState(() {
        _isTextCommand =
            startsWithPossibleCommands(_textEditingController.text);
      });
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _textEditingController.dispose();
    super.dispose();
  }

  bool startsWithPossibleCommands(String text) {
    if (text == "" || text.isEmpty) {
      return false;
    }
    final hasSlash =
        ChatMode.values.any((element) => element.title.startsWith(text));
    return hasSlash;
  }

  void sendMessage(String value) async {
    value = value.trim();
    if (value.isEmpty) {
      return;
    }
    if (value.startsWith('!')) {
      final commandsModel = Provider.of<CommandsModel>(context, listen: false);
      commandsModel.addCommand(Command(value, DateTime.now()));
    }
    ActionsAdapter.instance.send(widget.channel, value);
    setState(() => _textEditingController.clear());
  }

  Widget _buildEmotePicker(BuildContext context) {
    return EmotePickerWidget(
        channelId: widget.channel.channelId,
        onEmoteSelected: (emote) {
          setState(() {
            _textEditingController.text =
                "${_textEditingController.text} ${emote.code}";
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(children: [
        if (_isKeyboardVisible)
          if (_isTextCommand)
            SizedBox(
              height: 200,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: ChatMode.values
                    .where((element) =>
                        element.title.startsWith(_textEditingController.text))
                    .map((e) {
                  return ListTile(
                    title: Text(e.title),
                    subtitle: Text(e.subtitle),
                    onTap: () {
                      _textEditingController.text = e.title;
                      // move cursor position
                      _textEditingController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController.text.length));
                    },
                  );
                }).toList(),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    Consumer<CommandsModel>(builder: (context, model, child) {
                      return Wrap(
                        children: model.commandList.map((command) {
                          return TextButton(
                            child: Text(command.command),
                            onPressed: () {
                              ActionsAdapter.instance
                                  .send(widget.channel, command.command);

                              model.addCommand(
                                  Command(command.command, DateTime.now()));
                              _chatInputFocusNode.unfocus();
                            },
                          );
                        }).toList(),
                      );
                    }),
                  ]),
            ),
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
                                setState(() {
                                  _isEmotePickerVisible = true;
                                  _emoteIndex =
                                      Random().nextInt(_emotes.length);
                                });
                              }
                            },
                            splashRadius: 24,
                            icon: _isEmotePickerVisible
                                ? const Icon(Icons.keyboard_rounded)
                                : ColorFiltered(
                                    colorFilter: _greyscale,
                                    child: Image(
                                      image: ResilientNetworkImage(
                                          Uri.parse(_emotes[_emoteIndex])),
                                    ))),
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
                    setState(() {
                      _textEditingController.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController.text.length)));
                    });
                  },
                  onSubmitted: sendMessage,
                  onTap: () {
                    setState(() => _isEmotePickerVisible = false);
                    _chatInputFocusNode.requestFocus();
                  },
                ),
              ),
            ]),
          ),
        ),
        _isEmotePickerVisible ? _buildEmotePicker(context) : Container(),
      ]),
    );
  }
}

enum CommandType {
  slash,
  exclamation,
}
