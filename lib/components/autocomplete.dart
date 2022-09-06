import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_mode.dart';
import 'package:rtchat/models/chat_state.dart';
import 'package:rtchat/models/commands.dart';

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

  const AutocompleteWidget(
      {Key? key, required this.controller, required this.onSend})
      : super(key: key);

  @override
  State<AutocompleteWidget> createState() => _AutocompleteWidgetState();
}

class _AutocompleteWidgetState extends State<AutocompleteWidget> {
  var _autocompleteMode = _AutocompleteMode.none;

  @override
  void initState() {
    super.initState();

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
        // TODO: implement emote
        return Container();
      case _AutocompleteMode.slashCommand:
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: ChatMode.values
                .where((element) => element.title.startsWith(text))
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
        return Container(
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
                        onPressed: () => widget.onSend(command.command),
                      );
                    }).toList(),
                  );
                }),
              ]),
        );
      case _AutocompleteMode.mention:
        final username = text.split(" ").last.substring(1);
        return Consumer<ChatStateModel>(builder: (context, model, child) {
          return Row(
            children: model.viewers?.query(username).flatten().map((viewer) {
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
                }).toList() ??
                [],
          );
        });
    }
  }
}
