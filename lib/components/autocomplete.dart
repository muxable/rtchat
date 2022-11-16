import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/chat_mode.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

enum _AutocompleteMode {
  none,
  emote,
  slashCommand,
  bangCommand,
  mention,
}

extension _AutocompleteModeExtension on _AutocompleteMode {
  static _AutocompleteMode forText(String text) {
    if (text.startsWith("!") || text.isEmpty) {
      return _AutocompleteMode.bangCommand;
    } else if (text.startsWith("/")) {
      return _AutocompleteMode.slashCommand;
    }
    // get the last token in the string.
    final lastToken = text.split(" ").last;
    if (lastToken.startsWith("@")) {
      return _AutocompleteMode.mention;
    } else {
      return _AutocompleteMode.emote;
    }
  }
}

class AutocompleteWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final Channel channel;

  const AutocompleteWidget(
      {Key? key,
      required this.controller,
      required this.onSend,
      required this.channel})
      : super(key: key);

  @override
  State<AutocompleteWidget> createState() => _AutocompleteWidgetState();
}

class _AutocompleteWidgetState extends State<AutocompleteWidget> {
  var _autocompleteMode = _AutocompleteMode.none;
  late Future<List<Emote>> _emotes;

  @override
  void initState() {
    super.initState();

    _emotes = getEmotes(widget.channel);

    setState(() => _autocompleteMode =
        _AutocompleteModeExtension.forText(widget.controller.text));
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);

    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _autocompleteMode =
          _AutocompleteModeExtension.forText(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    switch (_autocompleteMode) {
      case _AutocompleteMode.none:
        return Container();
      case _AutocompleteMode.emote:
        return FutureBuilder(
          future: _emotes,
          builder: (context, snapshot) {
            final lastToken = text.split(" ").last;
            if (!snapshot.hasData || lastToken.isEmpty) {
              return Container();
            }
            return Row(
              children: (snapshot.data as List<Emote>)
                  .where((emote) => emote.code
                      .toLowerCase()
                      .startsWith(lastToken.toLowerCase()))
                  .take(MediaQuery.of(context).size.width ~/ 48)
                  .map((emote) {
                return IconButton(
                    tooltip: emote.code,
                    onPressed: () {
                      widget.controller.text = "${text.substring(
                        0,
                        text.length - lastToken.length,
                      )}${emote.code} ";
                      // move cursor position
                      widget.controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: widget.controller.text.length));
                    },
                    splashRadius: 24,
                    icon: Image(image: ResilientNetworkImage(emote.uri)));
              }).toList(),
            );
          },
        );
      case _AutocompleteMode.slashCommand:
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: ChatMode.values
                .where((element) =>
                    element.title.toLowerCase().startsWith(text.toLowerCase()))
                .map((e) {
              return ListTile(
                title: Text(e.title),
                subtitle: Text(e.subtitle),
                onTap: () => widget.onSend(e.title),
              );
            }).toList(),
          ),
        );
      case _AutocompleteMode.bangCommand:
        final commandPrefix = text.split(" ").last.toLowerCase();
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                Consumer<CommandsModel>(builder: (context, model, child) {
                  return Wrap(
                    children: model.commandList
                        .where((element) =>
                            element.command.startsWith(commandPrefix))
                        .map((command) {
                      return TextButton(
                        child: Text(command.command),
                        onPressed: () => widget.onSend(command.command),
                      );
                    }).toList(),
                  );
                }),
              ]),
        );
      case _AutocompleteMode.mention:
        final username = text.split(" ").last.substring(1);
        return Consumer<MessagesModel>(builder: (context, model, child) {
          return Row(
            children: model.authors
                .where((element) => element.login
                    .toLowerCase()
                    .contains(username.toLowerCase()))
                .map((viewer) {
              return TextButton(
                child: Text("@$viewer"),
                onPressed: () {
                  widget.controller.text = "${text.substring(
                    0,
                    text.length - username.length - 1,
                  )}@$viewer ";
                  // move cursor position
                  widget.controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: widget.controller.text.length));
                },
              );
            }).toList(),
          );
        });
    }
  }
}
