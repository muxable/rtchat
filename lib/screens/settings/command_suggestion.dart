import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/commands.dart';

class CommandSuggestionScreen extends StatelessWidget {
  const CommandSuggestionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Command Suggestion Settings"),
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
                      title: const Text('Enable suggestion'),
                      value: model.showCommandSuggestion,
                      onChanged: (value) {
                        model.showCommandSuggestion = value;
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Always on'),
                      subtitle: const Text('Keep command bar always on'),
                      value: model.alwaysOn,
                      onChanged: model.showCommandSuggestion
                          ? (value) {
                              model.alwaysOn = value;
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
