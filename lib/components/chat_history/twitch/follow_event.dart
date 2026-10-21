import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/decorated_event.dart';
import 'package:rtchat/components/image/resilient_network_image.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/style.dart';
import 'package:styled_text/styled_text.dart';

class TwitchFollowEventWidget extends StatefulWidget {
  final TwitchFollowEventModel model;

  const TwitchFollowEventWidget(this.model, {super.key});

  @override
  State<TwitchFollowEventWidget> createState() =>
      _TwitchFollowEventWidgetState();
}

class _TwitchFollowEventWidgetState extends State<TwitchFollowEventWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final followers = widget.model.followers;

    return Consumer<StyleModel>(
      builder: (context, styleModel, child) {
        return InkWell(
          onTap: followers.length > 1
              ? () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Expanded vertical follower list.
                        ...followers.map((follower) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Image(
                                      image: ResilientNetworkImage(
                                        follower.profilePictureUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    styleModel.getDisplayName(follower),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 8),

                        // Event description without duplicated names.
                        Text(
                          AppLocalizations.of(context)!.areFollowingYou,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    )
                  : DecoratedEventWidget.avatars(
                      avatars: followers.take(min(3, followers.length)).map(
                            (follower) => ResilientNetworkImage(
                              follower.profilePictureUrl,
                            ),
                          ),
                      child: _buildSummary(context, styleModel),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(
    BuildContext context,
    StyleModel styleModel,
  ) {
    final followers = widget.model.followers;
    final localizations = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.titleSmall;

    switch (followers.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return StyledText(
          text: localizations.followingEvent(
            styleModel.getDisplayName(followers.first),
          ),
          tags: {
            'bold': StyledTextTag(style: style),
          },
        );
      case 2:
        return StyledText(
          text: localizations.followingEvent2(
            styleModel.getDisplayName(followers.first),
            styleModel.getDisplayName(followers.last),
          ),
          tags: {
            'bold': StyledTextTag(style: style),
          },
        );
      default:
        return StyledText(
          text: localizations.followingEvent3(
            styleModel.getDisplayName(followers.first),
            styleModel.getDisplayName(followers.last),
            followers.length - 2,
          ),
          tags: {
            'bold': StyledTextTag(style: style),
          },
        );
    }
  }
}
