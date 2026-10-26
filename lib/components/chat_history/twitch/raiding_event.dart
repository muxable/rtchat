import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/views.dart';
import 'package:styled_text/styled_text.dart';

class TwitchRaidingEventWidget extends StatelessWidget {
  final TwitchRaidingEventModel model;
  final VoidCallback? onCancel;

  const TwitchRaidingEventWidget(this.model, {super.key, this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (!model.isComplete) {
      return StreamBuilder<int>(
        stream: Stream.periodic(const Duration(milliseconds: 500), (x) => x),
        builder: (context, snapshot) {
          final flash = snapshot.data == null || snapshot.data! % 2 == 0;
          final expiration = model.timestamp.add(model.duration);
          final remaining = expiration.difference(DateTime.now());
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  color:
                      flash
                          ? Theme.of(context).highlightColor
                          : Theme.of(context).colorScheme.secondary,
                ),
              ),
              DecoratedEventWidget.avatar(
                decoration: const BoxDecoration(color: Colors.transparent),
                avatar: CachedNetworkImageProvider(
                  model.targetUser.profilePictureUrl.toString(),
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
                    if (onCancel != null)
                      TextButton(
                        onPressed: onCancel,
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
          avatar: CachedNetworkImageProvider(
            model.targetUser.profilePictureUrl.toString(),
          ),
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
        avatar: CachedNetworkImageProvider(
          model.targetUser.profilePictureUrl.toString(),
        ),
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
