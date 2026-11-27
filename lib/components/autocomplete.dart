import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/chat_commands.dart';
import 'package:rtchat/models/chat_mode.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

enum _AutocompleteMode { none, emote, slashCommand, bangCommand, mention }

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
  final Future<List<Emote>> emotes;

  const AutocompleteWidget({
    super.key,
    required this.controller,
    required this.onSend,
    required this.emotes,
  });

  @override
  State<AutocompleteWidget> createState() => _AutocompleteWidgetState();
}

class _AutocompleteWidgetState extends State<AutocompleteWidget> {
  var _autocompleteMode = _AutocompleteMode.none;

  @override
  void initState() {
    super.initState();

    setState(
      () =>
          _autocompleteMode = _AutocompleteModeExtension.forText(
            widget.controller.text,
          ),
    );
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _autocompleteMode = _AutocompleteModeExtension.forText(
        widget.controller.text,
      );
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
          future: widget.emotes,
          builder: (context, snapshot) {
            final lastToken = text.split(" ").last;
            if (!snapshot.hasData || lastToken.isEmpty) {
              return Container();
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children:
                      (snapshot.data as List<Emote>)
                          .where(
                            (emote) => emote.code.toLowerCase().startsWith(
                              lastToken.toLowerCase(),
                            ),
                          )
                          .take(constraints.maxWidth ~/ 48)
                          .map((emote) {
                            return IconButton(
                              tooltip: emote.code,
                              onPressed: () {
                                widget.controller.text =
                                    "${text.substring(0, text.length - lastToken.length)}${emote.code} ";
                                // move cursor position
                                widget
                                    .controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(
                                    offset: widget.controller.text.length,
                                  ),
                                );
                              },
                              splashRadius: 24,
                              icon: Image(
                                width: 24,
                                height: 24,
                                filterQuality: FilterQuality.medium,
                                image: CachedNetworkImageProvider(
                                  emote.uri.toString(),
                                ),
                              ),
                            );
                          })
                          .toList(),
                );
              },
            );
          },
        );

      case _AutocompleteMode.slashCommand:
        final existingCommands =
            ChatMode.values
                .where(
                  (element) => element.title.toLowerCase().startsWith(
                    text.toLowerCase(),
                  ),
                )
                .toList();

        final additionalCommands =
            chatCommands.where((command) {
              return text.length > 1 &&
                  command.name.toLowerCase().startsWith(text.toLowerCase()) &&
                  !existingCommands.any(
                    (existing) =>
                        existing.title.toLowerCase() ==
                        command.name.toLowerCase(),
                  );
            }).toList();

        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...existingCommands
                        .take((constraints.maxWidth ~/ 80).clamp(1, 5))
                        .map((command) {
                          return TextButton(
                            onPressed: () {
                              widget.controller.text = '${command.title} ';
                              widget
                                  .controller
                                  .selection = TextSelection.collapsed(
                                offset: widget.controller.text.length,
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: command.title),
                                  if (command.arguments.isNotEmpty)
                                    TextSpan(
                                      text:
                                          ' ${command.arguments.map((e) => '[$e]').join(' ')}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).hintColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ...additionalCommands.map((command) {
                      return TextButton(
                        onPressed: () {
                          widget.controller.text = '${command.name} ';
                          widget.controller.selection = TextSelection.collapsed(
                            offset: widget.controller.text.length,
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: command.name),
                              if (command.arguments.isNotEmpty)
                                TextSpan(
                                  text:
                                      ' ${command.arguments.map((e) => '[$e]').join(' ')}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          );
        } else {
          // Portrait mode: original ListView of ListTiles
          return Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ...existingCommands.map((command) {
                  return ListTile(
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: command.title),
                          if (command.arguments.isNotEmpty)
                            TextSpan(
                              text:
                                  ' ${command.arguments.map((e) => '[$e]').join(' ')}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    subtitle: Text(command.subtitle),
                    onTap: () {
                      widget.controller.text = '${command.title} ';
                      widget.controller.selection = TextSelection.collapsed(
                        offset: widget.controller.text.length,
                      );
                    },
                  );
                }),
                ...additionalCommands.map((command) {
                  return ListTile(
                    title: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: command.name),
                          if (command.arguments.isNotEmpty)
                            TextSpan(
                              text:
                                  ' ${command.arguments.map((e) => '[$e]').join(' ')}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    subtitle:
                        command.description.isNotEmpty
                            ? Text(command.description)
                            : null,
                    onTap: () {
                      widget.controller.text = '${command.name} ';
                      widget.controller.selection = TextSelection.collapsed(
                        offset: widget.controller.text.length,
                      );
                    },
                  );
                }),
              ],
            ),
          );
        }
      case _AutocompleteMode.bangCommand:
        final commandPrefix = text.split(" ").last.toLowerCase();
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              Consumer<CommandsModel>(
                builder: (context, model, child) {
                  return Wrap(
                    children:
                        model.commandList
                            .where(
                              (element) =>
                                  element.command.startsWith(commandPrefix),
                            )
                            .map((command) {
                              return TextButton(
                                child: Text(command.command),
                                onPressed: () => widget.onSend(command.command),
                              );
                            })
                            .toList(),
                  );
                },
              ),
            ],
          ),
        );
      case _AutocompleteMode.mention:
        final username = text.split(" ").last.substring(1);
        return Consumer<MessagesModel>(
          builder: (context, model, child) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    model.authors
                        .where(
                          (element) => element.login.toLowerCase().contains(
                            username.toLowerCase(),
                          ),
                        )
                        .map((viewer) {
                          return TextButton(
                            child: Text("@$viewer"),
                            onPressed: () {
                              widget.controller.text =
                                  "${text.substring(0, text.length - username.length - 1)}@$viewer ";
                              // move cursor position
                              widget
                                  .controller
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: widget.controller.text.length,
                                ),
                              );
                            },
                          );
                        })
                        .toList(),
              ),
            );
          },
        );
    }
  }
}
