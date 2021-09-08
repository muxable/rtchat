import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class SubscriptionEventScreen extends StatelessWidget {
  const SubscriptionEventScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Subscription Configuration"),
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
                      value: model
                          .subscriptionEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label:
                          "${model.subscriptionEventConfig.eventDuration.inSeconds} seconds",
                      onChanged: (value) {
                        model.setSubscriptionEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: const Text('Enable event'),
                      subtitle: const Text('Show event in chat history'),
                      value: model.subscriptionEventConfig.showEvent,
                      onChanged: (value) {
                        model.setSubscriptionEventShowable(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title:
                          const Text('Enable individual gifted subscriptions'),
                      subtitle:
                          const Text('Show every subscription that is gifted'),
                      value: model.subscriptionEventConfig.showIndividualGifts,
                      onChanged: (value) {
                        model.setGiftSubscriptionStatus(value);
                      },
                    )
                  ],
                ),
              ),
            ],
          );
        }));
  }
}
