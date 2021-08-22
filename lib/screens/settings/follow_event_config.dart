import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class FollowEventConfigWidget extends StatelessWidget {
  const FollowEventConfigWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Follow Config"),
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
                      value: model.followEventConfig.eventDuration,
                      min: 2,
                      max: 14,
                      divisions: 4,
                      label: "${model.followEventConfig.eventDuration}seconds",
                      onChanged: (value) {
                        model.setFollowEventDuration(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('show event'),
                      value: model.followEventConfig.showEvent,
                      onChanged: (value) {
                        model.setFollowEventShowable(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('able to pin event'),
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
