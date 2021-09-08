import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Command {
  String _command;
  DateTime _timeLastUsed;

  Command(this._command, this._timeLastUsed);

  String get command => _command;

  DateTime get timeLastUsed => _timeLastUsed;

  @override
  bool operator ==(other) => other is Command && other.command == _command;

  @override
  String toString() => '$_command:$_timeLastUsed';
}

class CommandsModel extends ChangeNotifier {
  List<Command> _commandList = [];
  static const _maxNumberOfCommands = 10;

  List<Command> get commandList => _commandList;

  void clear() {
    _commandList.clear();
    notifyListeners();
  }

  void addCommand(Command command) {
    if (_commandList.contains(command)) {
      _commandList.remove(command);
    }
    if (_commandList.length >= _maxNumberOfCommands) {
      _commandList.removeLast();
    }
    _commandList.insert(0, command);
    notifyListeners();
  }

  CommandsModel.fromJson(Map<String, dynamic> json) {
    if (json['commands'] != null) {
      _commandList = List<Command>.from(json['commands']);
    }
  }

  Map<String, dynamic> toJson() => {'commands': _commandList};
}
