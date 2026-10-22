import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

class CheerEventScreen extends StatelessWidget {
  const CheerEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.cheerConfigurationTitle),
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
                    Text(
                      AppLocalizations.of(context)!.pinDuration,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider.adaptive(
                      value:
                          model.cheerEventConfig.eventDuration.inSeconds
                              .toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 15,
                      label: AppLocalizations.of(context)!.durationSeconds(
                        model.cheerEventConfig.eventDuration.inSeconds,
                      ),
                      onChanged: (value) {
                        model.setCheerEventDuration(
                          Duration(seconds: value.toInt()),
                        );
                      },
                    ),
                    SwitchListTile.adaptive(
                      title: Text(AppLocalizations.of(context)!.enableEvent),
                      subtitle: Text(
                        AppLocalizations.of(context)!.showEventInChatHistory,
                      ),
                      value: model.cheerEventConfig.showEvent,
                      onChanged: (value) {
                        model.setCheerEventShowable(value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
