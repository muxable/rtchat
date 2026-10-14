import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class RaidEventScreen extends StatelessWidget {
  const RaidEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.raidConfigurationTitle),
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
                    Text(AppLocalizations.of(context)!.pinDuration,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        )),
                    Slider.adaptive(
                      value: model.raidEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label: AppLocalizations.of(context)!.durationSeconds(
                          model.raidEventConfig.eventDuration.inSeconds),
                      onChanged: (value) {
                        model.setRaidEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: Text(AppLocalizations.of(context)!.enableEvent),
                      subtitle: Text(
                          AppLocalizations.of(context)!.showEventInChatHistory),
                      value: model.raidEventConfig.showEvent,
                      onChanged: (value) {
                        model.setRaidEventShowable(value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      title:
                          Text(AppLocalizations.of(context)!.enableShoutouts),
                      subtitle: Text(AppLocalizations.of(context)!
                          .enableShoutoutsSubtitle),
                      value: model.raidEventConfig.enableShoutoutButton,
                      onChanged: (value) {
                        model.setRaidEventEnableShoutoutButton(value);
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
