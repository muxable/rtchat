import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// class Command {
//   final String prefix;
//   final String word;

//   Command(this.prefix, this.word);

//   Command.fromJson(Map<String, dynamic> json)
//       : prefix = json['prefix'],
//         word = json['word'];

//   Map<String, dynamic> toJson() => {
//         "prefix": prefix,
//         "word": word,
//       };

//   @override
//   String toString() => "$prefix$word";
// }

class CommandsModel extends ChangeNotifier {
  List<String> _commands = [];
  static const _maxNumberOfCommands = 10;

  List<String> get commands => _commands;

  void clear() {
    _commands = [];
  }

  void addCommand(String command) {
    if (_commands.contains(command)) {
      _commands.remove(command);
    }
    if (_commands.length >= _maxNumberOfCommands) {
      _commands.removeLast();
    }
    _commands.insert(0, command);
    notifyListeners();
  }

  CommandsModel.fromJson(Map<String, dynamic> json) {
    final commands = json['commands'];
    if (commands != null) {
      _commands.add(commands);
    }
  }

  Map<String, dynamic> toJson() => {"commands": _commands};
}
