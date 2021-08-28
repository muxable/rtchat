import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class FollowEventScreen extends StatelessWidget {
  const FollowEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Follow Configuration"),
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
                      value: model.followEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 2,
                      max: 14,
                      divisions: 4,
                      label:
                          "${model.followEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setFollowEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.followEventConfig.showEvent,
                      onChanged: (value) {
                        model.setFollowEventShowable(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Pin event'),
                      subtitle: const Text('Pin event to chat history'),
                      value: model.followEventConfig.isEventPinnable,
                      onChanged: (value) {
                        model.setFollowEventPinnable(value);
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
