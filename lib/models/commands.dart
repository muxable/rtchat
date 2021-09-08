import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CommandsModel extends ChangeNotifier {
  var _showCommandSuggestion = true;
  var _alwaysOn = false;
  List<String> _commands = [];
  static const _maxNumberOfCommands = 10;

  bool get showCommandSuggestion => _showCommandSuggestion;

  set showCommandSuggestion(bool value) {
    _showCommandSuggestion = value;
    notifyListeners();
  }

  bool get alwaysOn => _alwaysOn;

  set alwaysOn(bool value) {
    _alwaysOn = value;
    notifyListeners();
  }

  List<String> get commands => _commands;

  void clear() {
    _commands.clear();
    notifyListeners();
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
    if (json['commands'] != null) {
      _commands = List<String>.from(json['commands']);
    }
    if (json['showCommandSuggestion'] != null) {
      _showCommandSuggestion = json['showCommandSuggestion'];
    }
    if (json['alwaysOn'] != null) {
      _alwaysOn = json['alwaysOn'];
    }
  }

  Map<String, dynamic> toJson() => {
        'commands': _commands,
        'showCommandSuggestion': _showCommandSuggestion,
        'alwaysOn': _alwaysOn,
      };
}
