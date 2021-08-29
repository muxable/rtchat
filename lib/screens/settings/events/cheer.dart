import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class CheerEventScreen extends StatelessWidget {
  const CheerEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Cheer Configuration"),
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
                          color: Theme.of(context).accentColor,
                          fontWeight: FontWeight.bold,
                        )),
                    Slider.adaptive(
                      value: model.cheerEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 2,
                      max: 14,
                      divisions: 4,
                      label:
                          "${model.cheerEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setCheerEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.cheerEventConfig.showEvent,
                      onChanged: (value) {
                        model.setCheerEventShowable(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Pin event'),
                      subtitle: const Text('Pin event to chat history'),
                      value: model.cheerEventConfig.isEventPinnable,
                      onChanged: (value) {
                        model.setCheerEventPinnable(value);
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
