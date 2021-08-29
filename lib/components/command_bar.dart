import 'dart:html';

import 'package:flutter/material.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/adapters/actions.dart';

class CommandBarWidget extends StatelessWidget {
  // final void Function() onPressed;
  final CommandsModel commandsModel;
  final ChannelsModel channelsModel;
  final FocusNode chatInputFocusNode;
  static const _commandBarHeight = 55.0;

  const CommandBarWidget(
      {Key? key,
      required this.commandsModel,
      required this.channelsModel,
      required this.chatInputFocusNode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _commandBarHeight,
      child: Scrollbar(
        isAlwaysShown: false,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _commandButtonsBuilder(commandsModel),
        ),
      ),
    );
  }

  List<TextButton> _commandButtonsBuilder(CommandsModel commandsModel) {
    List<TextButton> commandButtons = [];
    for (String command in commandsModel.commands) {
      commandButtons.add(TextButton(
        child: Text(command),
        onPressed: () {
          ActionsAdapter.instance
              .send(channelsModel.subscribedChannels.first, command);
          commandsModel.addCommand(command);
          chatInputFocusNode.unfocus();
        },
      ));
    }
    commandButtons.add(
      TextButton(
          child: const Text('Clear'),
          onPressed: () {
            commandsModel.clear();
            chatInputFocusNode.unfocus();
          },
          style: TextButton.styleFrom(
            primary: Colors.red,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          )),
    );
    return commandButtons;
  }
}
