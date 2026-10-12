import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/commands.dart';

void main() {
  group("Command", () {
    test("equality only considers the command text", () {
      final a = Command("!lurk", DateTime(2020));
      final b = Command("!lurk", DateTime(2024));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(Command("!hype", DateTime(2020)))));
    });

    test("isDead after seven days", () {
      final now = DateTime.now();
      expect(Command("!a", now).isDead, isFalse);
      expect(
          Command("!a", now.subtract(const Duration(days: 6))).isDead, isFalse);
      expect(
          Command("!a", now.subtract(const Duration(days: 7))).isDead, isTrue);
      expect(
          Command("!a", now.subtract(const Duration(days: 30))).isDead, isTrue);
    });

    test("json round trip", () {
      final command = Command("!so", DateTime(2024, 5, 6, 7, 8, 9));
      final decoded = Command.fromJson(command.toJson());
      expect(decoded.command, "!so");
      expect(decoded.timeLastUsed, DateTime(2024, 5, 6, 7, 8, 9));
    });
  });

  group("CommandsModel", () {
    test("adds new commands to the front", () {
      final model = CommandsModel.fromJson({});
      model.addCommand(Command("!a", DateTime.now()));
      model.addCommand(Command("!b", DateTime.now()));
      expect(model.commandList.map((c) => c.command), ["!b", "!a"]);
    });

    test("re-adding an existing command moves it to the front", () {
      final model = CommandsModel.fromJson({});
      for (final c in ["!a", "!b", "!c"]) {
        model.addCommand(Command(c, DateTime.now()));
      }
      model.addCommand(Command("!a", DateTime.now()));
      expect(model.commandList.map((c) => c.command), ["!a", "!c", "!b"]);
    });

    test("caps the list and evicts the oldest command", () {
      final model = CommandsModel.fromJson({});
      for (var i = 0; i < CommandsModel.maxNumberOfCommands + 3; i++) {
        model.addCommand(Command("!c$i", DateTime.now()));
      }
      expect(model.commandList.length, CommandsModel.maxNumberOfCommands);
      expect(model.commandList.first.command, "!c17");
      expect(model.commandList.last.command, "!c3");
    });

    test("re-adding at capacity does not evict another command", () {
      final model = CommandsModel.fromJson({});
      for (var i = 0; i < CommandsModel.maxNumberOfCommands; i++) {
        model.addCommand(Command("!c$i", DateTime.now()));
      }
      model.addCommand(Command("!c0", DateTime.now()));
      expect(model.commandList.length, CommandsModel.maxNumberOfCommands);
      expect(model.commandList.first.command, "!c0");
      expect(model.commandList.map((c) => c.command), contains("!c1"));
    });

    test("notifies listeners on add and clear", () {
      final model = CommandsModel.fromJson({});
      var count = 0;
      model.addListener(() => count++);
      model.addCommand(Command("!a", DateTime.now()));
      model.clear();
      expect(count, 2);
      expect(model.commandList, isEmpty);
    });

    test("json round trip through jsonEncode", () {
      final model = CommandsModel.fromJson({});
      model.addCommand(Command("!a", DateTime.now()));
      model.addCommand(Command("!b", DateTime.now()));
      final decoded = CommandsModel.fromJson(
          jsonDecode(jsonEncode(model.toJson())) as Map<String, dynamic>);
      expect(decoded.commandList.map((c) => c.command), ["!b", "!a"]);
    });

    test("fromJson drops dead commands", () {
      final now = DateTime.now();
      final model = CommandsModel.fromJson({
        "commandList": [
          Command("!fresh", now).toJson(),
          Command("!stale", now.subtract(const Duration(days: 8))).toJson(),
        ]
      });
      expect(model.commandList.map((c) => c.command), ["!fresh"]);
    });
  });
}
