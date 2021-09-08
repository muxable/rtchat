import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class ChannelPointRedemptionEventScreen extends StatelessWidget {
  const ChannelPointRedemptionEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Channel Point Configuration"),
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
                      value: model.channelPointRedemptionEventConfig
                          .eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label:
                          "${model.channelPointRedemptionEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setChannelPointRedemptionEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    Text("Additional Pin Duration for Unfulfilled Rewards",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    Slider.adaptive(
                      value: model.channelPointRedemptionEventConfig
                          .unfulfilledAdditionalDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label:
                          "${model.channelPointRedemptionEventConfig.unfulfilledAdditionalDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model
                            .setChannelPointRedemptionEventUnfulfilledAdditionalDuration(
                                Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.channelPointRedemptionEventConfig.showEvent,
                      onChanged: (value) {
                        model.setChannelPointRedemptionEventShowable(value);
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        }));
  }
}
