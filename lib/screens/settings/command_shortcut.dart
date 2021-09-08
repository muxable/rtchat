import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/commands.dart';

class CommandShortcutScreen extends StatelessWidget {
  const CommandShortcutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Command Shortcut Settings"),
        ),
        body: Consumer<CommandsModel>(builder: (context, model, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(' "!" commands are added automatically',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          )),
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable shortcut'),
                      value: model.showCommandShortcut,
                      onChanged: (value) {
                        model.showCommandShortcut = value;
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Always on'),
                      subtitle: const Text('Keep command shortcut always on'),
                      value: model.isAlwaysOn,
                      onChanged: model.showCommandShortcut
                          ? (value) {
                              model.isAlwaysOn = value;
                            }
                          : null,
                    ),
                    ListTile(
                      title: const Text('Clear all commands',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Confirm?'),
                              content:
                                  const Text('Commands cannot be recovered'),
                              actions: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Cancel")),
                                ElevatedButton(
                                    onPressed: () {
                                      model.clear();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Clear")),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }));
  }
}
