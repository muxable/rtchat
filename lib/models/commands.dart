import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Command {
  final String command;
  final DateTime timeLastUsed;
  static const daysToLive = Duration(days: 7);

  Command(this.command, this.timeLastUsed);

  bool get isDead => DateTime.now().difference(timeLastUsed) >= daysToLive;

  @override
  int get hashCode => command.hashCode;

  @override
  bool operator ==(other) => other is Command && other.command == command;

  @override
  String toString() => '$command:$timeLastUsed';

  Command.fromJson(Map<String, dynamic> json)
      : command = json['command'],
        timeLastUsed = DateTime.parse(json['timeLastUsed']);

  Map<String, dynamic> toJson() => {
        'command': command,
        'timeLastUsed': timeLastUsed.toString(),
      };
}

class CommandsModel extends ChangeNotifier {
  List<Command> commandList = [];
  static const maxNumberOfCommands = 15;

  void clear() {
    commandList.clear();
    notifyListeners();
  }

  void addCommand(Command command) {
    if (commandList.contains(command)) {
      commandList.remove(command);
    }
    if (commandList.length >= maxNumberOfCommands) {
      commandList.removeLast();
    }
    commandList.insert(0, command);
    notifyListeners();
  }

  CommandsModel.fromJson(Map<String, dynamic> json) {
    if (json['commandList'] != null) {
      for (var item in json['commandList']) {
        Command command = Command.fromJson(item);
        if (!command.isDead) {
          commandList.add(command);
        } else {
          break;
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {'commandList': commandList};
}
