import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/views.dart';
import 'package:styled_text/styled_text.dart';

class TwitchRaidingEventWidget extends StatefulWidget {
  final TwitchRaidingEventModel model;
  final Future<void> Function()? onCancel;

  const TwitchRaidingEventWidget(this.model, {super.key, this.onCancel});

  @override
  State<TwitchRaidingEventWidget> createState() =>
      _TwitchRaidingEventWidgetState();
}

class _TwitchRaidingEventWidgetState extends State<TwitchRaidingEventWidget> {
  bool _inFlight = false;

  Future<void> _cancel() async {
    if (_inFlight || widget.onCancel == null) return;
    setState(() => _inFlight = true);
    try {
      await widget.onCancel!();
    } finally {
      if (mounted) {
        setState(() => _inFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    if (!model.isComplete) {
      return StreamBuilder<int>(
        stream: Stream.periodic(const Duration(milliseconds: 500), (x) => x),
        builder: (context, snapshot) {
          final expiration = model.timestamp.add(model.duration);
          final remaining = expiration.difference(DateTime.now());
          final countdownActive = remaining > Duration.zero;
          final flash = snapshot.data == null || snapshot.data! % 2 == 0;
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  color:
                      !countdownActive
                          ? Theme.of(context).highlightColor
                          : flash
                          ? Theme.of(context).highlightColor
                          : Theme.of(context).colorScheme.secondary,
                ),
              ),
              DecoratedEventWidget.avatar(
                decoration: const BoxDecoration(color: Colors.transparent),
                avatar: ResilientNetworkImage(
                  model.targetUser.profilePictureUrl,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StyledText(
                        text: AppLocalizations.of(context)!.raidingEventRaiding(
                          model.targetUser.displayName ??
                              AppLocalizations.of(context)!.anonymous,
                        ),
                        tags: {
                          'b': StyledTextTag(
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        },
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        text:
                            remaining.isNegative
                                ? AppLocalizations.of(
                                  context,
                                )!.raidingEventTimeRemaining(0)
                                : AppLocalizations.of(
                                  context,
                                )!.raidingEventTimeRemaining(
                                  remaining.inSeconds + 1,
                                ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (widget.onCancel != null &&
                        remaining > const Duration(seconds: 1))
                      TextButton(
                        onPressed: _inFlight ? null : _cancel,
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    } else if (model.isSuccessful) {
      return GestureDetector(
        child: DecoratedEventWidget.avatar(
          avatar: ResilientNetworkImage(model.targetUser.profilePictureUrl),
          child: Row(
            children: [
              Expanded(
                child: StyledText(
                  text: AppLocalizations.of(context)!.raidingEventRaided(
                    model.targetUser.displayName ??
                        AppLocalizations.of(context)!.anonymous,
                  ),
                  tags: {
                    'b': StyledTextTag(
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  },
                ),
              ),
              Text.rich(
                TextSpan(
                  text: AppLocalizations.of(context)!.raidingEventJoin,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).buttonTheme.colorScheme?.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        onTap: () {
          Provider.of<ViewsModel>(
            context,
            listen: false,
          ).openChannel(model.targetUser.asChannel);
        },
      );
    } else {
      return DecoratedEventWidget.avatar(
        avatar: ResilientNetworkImage(model.targetUser.profilePictureUrl),
        child: StyledText(
          text: AppLocalizations.of(context)!.raidingEventCanceled(
            model.targetUser.displayName ??
                AppLocalizations.of(context)!.anonymous,
          ),
          tags: {
            'b': StyledTextTag(style: Theme.of(context).textTheme.titleSmall),
          },
        ),
      );
    }
  }
}
