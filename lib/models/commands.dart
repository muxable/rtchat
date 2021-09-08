import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CommandsModel extends ChangeNotifier {
  var _showCommandShortcut = true;
  var _isAlwaysOn = false;
  List<String> _commands = [];
  static const _maxNumberOfCommands = 15;

  bool get showCommandShortcut => _showCommandShortcut;

  set showCommandShortcut(bool value) {
    _showCommandShortcut = value;
    notifyListeners();
  }

  bool get isAlwaysOn => _isAlwaysOn;

  set isAlwaysOn(bool value) {
    _isAlwaysOn = value;
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
    if (json['showCommandShortcut'] != null) {
      _showCommandShortcut = json['showCommandShortcut'];
    }
    if (json['isAlwaysOn'] != null) {
      _isAlwaysOn = json['isAlwaysOn'];
    }
  }

  Map<String, dynamic> toJson() => {
        'commands': _commands,
        'showCommandShortcut': _showCommandShortcut,
        'isAlwaysOn': _isAlwaysOn,
      };
}
