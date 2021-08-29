import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
      _commands.removeAt(
          _maxNumberOfCommands - 2); // remove 2nd last, last is clear button
    }
    _commands.insert(0, command);
    notifyListeners();
  }

  CommandsModel.fromJson(Map<String, dynamic> json) {
    if (json['commands'] != null) {
      final commands = List<String>.from(json['commands']);
      _commands = commands;
    }
  }

  Map<String, dynamic> toJson() => {"commands": _commands};
}
