import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/adapters/actions.dart';

class CommandBarWidget extends StatelessWidget {
  final void Function() chatInputUnfocus;
  static const _commandBarHeight = 55.0;

  const CommandBarWidget({Key? key, required this.chatInputUnfocus})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _commandBarHeight,
      child: Scrollbar(
        isAlwaysShown: false,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _commandButtonsBuilder(context),
        ),
      ),
    );
  }

  List<TextButton> _commandButtonsBuilder(context) {
    List<TextButton> commandButtons = [];
    final commandsModel = Provider.of<CommandsModel>(context, listen: false);
    for (String command in commandsModel.commands) {
      commandButtons.add(TextButton(
        child: Text(command),
        onPressed: () {
          final channelsModel =
              Provider.of<ChannelsModel>(context, listen: false);
          ActionsAdapter.instance
              .send(channelsModel.subscribedChannels.first, command);
          commandsModel.addCommand(command);
          chatInputUnfocus();
        },
      ));
    }
    return commandButtons;
  }
}
