import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class HostEventScreen extends StatelessWidget {
  const HostEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Host Configuration"),
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
                      value: model.hostEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label:
                          "${model.hostEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setHostEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.hostEventConfig.showEvent,
                      onChanged: (value) {
                        model.setHostEventShowable(value);
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
