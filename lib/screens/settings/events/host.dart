import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class HostEventScreen extends StatelessWidget {
  const HostEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.hostConfigurationTitle),
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
                      value: model.hostEventConfig.eventDuration.inSeconds
                          .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label: AppLocalizations.of(context)!.durationSeconds(
                          model.hostEventConfig.eventDuration.inSeconds),
                      onChanged: (value) {
                        model.setHostEventDuration(
                            Duration(seconds: value.toInt()));
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: Text(AppLocalizations.of(context)!.enableEvent),
                      subtitle: Text(
                          AppLocalizations.of(context)!.showEventInChatHistory),
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
