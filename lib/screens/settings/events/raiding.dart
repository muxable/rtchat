import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class RaidingEventScreen extends StatelessWidget {
  const RaidingEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Outgoing Raid Configuration"),
        ),
        body: Consumer<EventSubConfigurationModel>(
            builder: (context, model, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pin Duration",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    Slider.adaptive(
                      value: model.raidingEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 150,
                      divisions: 15,
                      label:
                          "${model.raidingEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setRaidingEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.raidingEventConfig.showEvent,
                      onChanged: (value) {
                        model.setRaidingEventShowable(value);
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
