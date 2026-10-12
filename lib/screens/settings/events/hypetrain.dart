import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class HypetrainEventScreen extends StatelessWidget {
  const HypetrainEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Text(AppLocalizations.of(context)!.hypetrainConfigurationTitle),
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
                    Text(AppLocalizations.of(context)!.hypetrainPinDuration,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    Slider.adaptive(
                      value: model.hypetrainEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label: AppLocalizations.of(context)!.durationSeconds(
                          model.hypetrainEventConfig.eventDuration.inSeconds),
                      onChanged: (value) {
                        model.setHypetrainEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: Text(AppLocalizations.of(context)!.enableEvent),
                      subtitle: Text(
                          AppLocalizations.of(context)!.showEventInChatHistory),
                      value: model.hypetrainEventConfig.showEvent,
                      onChanged: (value) {
                        model.setHypetrainEventShowable(value);
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
