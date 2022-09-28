import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/autocomplete.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/adapters/actions.dart';
import 'package:rtchat/models/channels.dart';
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
  var _isKeyboardVisible = false;
  late StreamSubscription keyboardSubscription;
  var _emoteIndex = Random().nextInt(_emotes.length);
  final _textSeed = Random().nextDouble();
  final List<String> _pendingSend = [];

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
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _textEditingController.dispose();
    super.dispose();
  }

  void sendMessage(String value) async {
    value = value.trim();
    if (value.isEmpty) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (value.startsWith('!')) {
      final commandsModel = Provider.of<CommandsModel>(context, listen: false);
      commandsModel.addCommand(Command(value, DateTime.now()));
    }
    setState(() {
      _textEditingController.clear();
    });
    var done = false;
    await Future.wait([
      () async {
        try {
          final error =
              await ActionsAdapter.instance.send(widget.channel, value);
          if (error != null) {
            messenger.showSnackBar(SnackBar(
              content: Text(error),
            ));
          }
        } catch (e) {
          messenger.showSnackBar(SnackBar(
            content: Text(e.toString()),
          ));
        }
        done = true;
        setState(() {
          _pendingSend.remove(value);
        });
      }(),
      () async {
        await Future.delayed(const Duration(seconds: 1));
        if (!done) {
          setState(() {
            _pendingSend.add(value);
          });
        }
      }(),
    ]);
  }

  Widget _buildEmotePicker(BuildContext context) {
    return EmotePickerWidget(
        channel: widget.channel,
        onEmoteSelected: (emote) {
          if (emote == null) {
            setState(() {
              _isEmotePickerVisible = false;
            });
            return;
          }
          setState(() {
            _textEditingController.text =
                "${_textEditingController.text} ${emote.code}";
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // render pending sends
        ..._pendingSend.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child:
                  Text(e, style: const TextStyle(fontStyle: FontStyle.italic)),
            )),
        if (_isKeyboardVisible)
          AutocompleteWidget(
            controller: _textEditingController,
            onSend: sendMessage,
            channel: widget.channel,
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
                      hintText: () {
                        final l10n = AppLocalizations.of(context)!;
                        if (_textSeed < 0.5) {
                          return l10n.sendAMessage;
                        } else if (_textSeed < 0.9) {
                          return l10n.writeSomething;
                        } else if (_textSeed < 0.99) {
                          return l10n.speakToTheCrowds;
                        } else if (_textSeed < 0.999) {
                          return l10n.shareYourThoughts;
                        }
                        return l10n.saySomethingYouLittleBitch;
                      }()),
                  onChanged: (text) {
                    final filtered = text.replaceAll('\n', ' ');
                    if (filtered == text) {
                      return;
                    }
                    setState(() {
                      _textEditingController.value = TextEditingValue(
                          text: filtered,
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
