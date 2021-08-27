import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Command {
  final String prefix;
  final String word;

  Command(this.prefix, this.word);

  Command.fromJson(Map<String, dynamic> json)
      : prefix = json['prefix'],
        word = json['word'];

  Map<String, dynamic> toJson() => {
        "prefix": prefix,
        "word": word,
      };

  @override
  String toString() => "$prefix$word";
}

class CommandsModel extends ChangeNotifier {
  final List<Command> _commands = [];
  static const _maxNumberOfCommands = 10;

  List<Command> get commands => _commands;

  void addCommand(Command command) {
    if (_commands.length == _maxNumberOfCommands) {
      _commands.removeLast();
    }
    _commands.insert(
        0, command); // command is always added to the first index (last used)
    notifyListeners();
  }

  CommandsModel.fromJson(Map<String, dynamic> json) {
    final commands = json['commands'];
    if (commands != null) {
      for (dynamic command in commands) {
        _commands.add(Command.fromJson(command));
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "commands": _commands.map((command) => command.toJson()).toList(),
      };
}
