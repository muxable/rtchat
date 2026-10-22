import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/channel_attribution.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/components/chat_history/separator.dart';
import 'package:rtchat/components/connection_status.dart';
import 'package:rtchat/components/pinnable/reverse_refresh_indicator.dart';
import 'package:rtchat/components/pinnable/scroll_view.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

class RebuildableWidget extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final Set<DateTime> rebuildAt;

  const RebuildableWidget({
    super.key,
    required this.builder,
    required this.rebuildAt,
  });

  @override
  State<RebuildableWidget> createState() => _RebuildableWidgetState();
}

class _RebuildableWidgetState extends State<RebuildableWidget> {
  Set<Timer> timers = {};

  @override
  void initState() {
    super.initState();
    _setTimers();
  }

  @override
  void didUpdateWidget(RebuildableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!setEquals(oldWidget.rebuildAt, widget.rebuildAt)) {
      _clearTimers();
      _setTimers();
    }
  }

  @override
  void dispose() {
    _clearTimers();
    super.dispose();
  }

  void _setTimers() {
    final now = DateTime.now();
    timers = widget.rebuildAt.expand((dateTime) sync* {
      final duration = dateTime.difference(now);
      if (!duration.isNegative) {
        yield Timer(duration, () {
          if (mounted) {
            setState(() {});
          }
        });
      }
    }).toSet();
  }

  void _clearTimers() {
    for (final timer in timers) {
      timer.cancel();
    }
    timers.clear();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

DateTime? _getExpiration(
  MessageModel model,
  EventSubConfigurationModel eventSubConfigurationModel,
  MessagesModel messagesModel,
) {
  if (model is TwitchRaidEventModel) {
    final config = eventSubConfigurationModel.raidEventConfig;
    return config.eventDuration > Duration.zero
        ? model.timestamp.add(config.eventDuration)
        : null;
  } else if (model is TwitchHostEventModel) {
    final config = eventSubConfigurationModel.hostEventConfig;
    return config.eventDuration > Duration.zero
        ? model.timestamp.add(config.eventDuration)
        : null;
  } else if (model is TwitchFollowEventModel) {
    final config = eventSubConfigurationModel.followEventConfig;
    return config.eventDuration > Duration.zero
        ? model.timestamp.add(config.eventDuration)
        : null;
  } else if (model is TwitchCheerEventModel) {
    final config = eventSubConfigurationModel.cheerEventConfig;
    return config.eventDuration > Duration.zero
        ? model.timestamp.add(config.eventDuration)
        : null;
  } else if (model is TwitchSubscriptionEventModel ||
      model is TwitchSubscriptionGiftEventModel ||
      model is TwitchSubscriptionMessageEventModel) {
    final config = eventSubConfigurationModel.subscriptionEventConfig;
    return config.eventDuration > Duration.zero
        ? model.timestamp.add(config.eventDuration)
        : null;
  } else if (model is TwitchPollEventModel) {
    final config = eventSubConfigurationModel.pollEventConfig;
    if (model.status == 'archived' || model.status == 'terminated') {
      return null;
    }
    return model.endTimestamp.add(config.eventDuration);
  } else if (model is TwitchChannelPointRedemptionEventModel) {
    final config = eventSubConfigurationModel.channelPointRedemptionEventConfig;
    final unfulfilledDuration =
        config.eventDuration + config.unfulfilledAdditionalDuration;

    if (model.status == TwitchChannelPointRedemptionStatus.unfulfilled &&
        unfulfilledDuration > Duration.zero) {
      return model.timestamp.add(unfulfilledDuration);
    }
    if (model.status == TwitchChannelPointRedemptionStatus.fulfilled &&
        config.eventDuration > Duration.zero) {
      return model.timestamp.add(config.eventDuration);
    }
    return null;
  } else if (model is TwitchHypeTrainEventModel) {
    final config = eventSubConfigurationModel.hypetrainEventConfig;
    return model.endTimestamp.add(config.eventDuration);
  } else if (model is TwitchPredictionEventModel) {
    final config = eventSubConfigurationModel.predictionEventConfig;

    if (model.status == 'canceled') {
      return null;
    }

    return model.endTime.add(config.eventDuration);
  } else if (model is TwitchMessageModel &&
      model.annotations.announcement != null) {
    return messagesModel.announcementPinDuration > Duration.zero
        ? model.timestamp.add(messagesModel.announcementPinDuration)
        : null;
  }

  return null;
}

class _ScrollToBottomWidget extends StatelessWidget {
  final bool show;
  final void Function() onPressed;
  final Widget? child;

  const _ScrollToBottomWidget({
    required this.show,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: show ? 16 : -72,
      curve: Curves.easeOut,
      child: Center(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_downward),
              child ?? Container(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayedMessage {
  final MessageModel message;
  final String key;
  final String? followGroupKey;

  const _DisplayedMessage({
    required this.message,
    required this.key,
    this.followGroupKey,
  });
}

class ChatPanelWidget extends StatefulWidget {
  final Channel channel;

  const ChatPanelWidget({
    required this.channel,
    super.key,
  });

  @override
  State<ChatPanelWidget> createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget>
    with TickerProviderStateMixin {
  final Set<String> _expandedFollowGroups = {};
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  final _controller = ScrollController(keepScrollOffset: true);

// don't render anything after this message if not null.
  MessageModel? _pauseAt;
  MessageModel? _lastMessage;
  var _atBottom = true;
  var _refreshPending = false;
  var _showScrollNotification = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(updateScrollPosition);
  }

  @override
  void didUpdateWidget(ChatPanelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.channel != widget.channel) {
      _expandedFollowGroups.clear();
      if (_controller.hasClients) {
        _controller.jumpTo(0);
      }
      setState(() {
        _atBottom = true;
        _pauseAt = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(updateScrollPosition);
    _controller.dispose();
    super.dispose();
  }

  void updateScrollPosition() async {
    if (!_controller.hasClients) return;
    if (_controller.position.maxScrollExtent - _controller.offset < 100) {
      if (_refreshPending) return;
      _refreshPending = true;
      final model = Provider.of<MessagesModel>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final localizations = AppLocalizations.of(context)!;
      await model.pullMoreMessages();
      _refreshPending = false;
      if (!mounted) return;
      if (_showScrollNotification && model.messages.length > 5000) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(localizations.longScrollNotification),
            action: SnackBarAction(
              label: localizations.stfu,
              onPressed: () {
                setState(() {
                  _showScrollNotification = false;
                });
              },
            ),
          ),
        );
      }
    }
    if (!_controller.hasClients) return;
    final value = _controller.position.atEdge && _controller.offset == 0;
    if (_atBottom != value) {
      setState(() {
        _atBottom = value;
        _pauseAt = value ? null : _lastMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.topCenter,
      children: [
        Consumer2<MessagesModel, EventSubConfigurationModel>(
          builder: (
            context,
            messagesModel,
            eventSubConfigurationModel,
            child,
          ) {
            var messages = messagesModel.messages.reversed.toList();
            _lastMessage = messages.isEmpty ? null : messages.first;
            if (messages.isEmpty) {
              return FutureBuilder<bool>(
                future: MessagesAdapter.instance.hasMessages(widget.channel),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == false) {
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppLocalizations.of(context)!.noMessagesEmptyState,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              );
            }
            var dropped = 0;
            if (_pauseAt != null) {
              final index = messages.indexOf(_pauseAt!);
              if (index != -1) {
                dropped = index;
                messages = messages.sublist(index);
              }
            } else {
              messagesModel.pruneMessages();
            }

            final displayedMessages = <_DisplayedMessage>[];

            for (var index = 0; index < messages.length; index++) {
              final message = messages[index];

              if (message is! TwitchFollowEventModel) {
                displayedMessages.add(
                  _DisplayedMessage(
                    message: message,
                    key: message.messageId,
                  ),
                );
                continue;
              }

              final channel = message.channel;

              bool sameRun(MessageModel element) =>
                  element is TwitchFollowEventModel &&
                  element.channel == channel;

              // Process only the end of each adjacent run.
              if (index != messages.length - 1 &&
                  sameRun(messages[index + 1])) {
                continue;
              }

              final lastIndex = messages.lastIndexWhere(
                (element) => !sameRun(element),
                index,
              );

              final group = TwitchFollowEventModel.merged(
                messages.sublist(lastIndex + 1, index + 1).reversed.toList(),
              );

              final groupKey = 'follow-${group.channel}-${group.messageId}';

              if (_expandedFollowGroups.contains(groupKey)) {
                for (var followerIndex = 0;
                    followerIndex < group.followers.length;
                    followerIndex++) {
                  final follower = group.followers[followerIndex];

                  final individual = TwitchFollowEventModel(
                    followers: [follower],
                    messageId: '${group.messageId}-follower-$followerIndex',
                    timestamp: group.timestamp,
                  )..channel = group.channel;

                  displayedMessages.add(
                    _DisplayedMessage(
                      message: individual,
                      key: '$groupKey-follower-$followerIndex',
                    ),
                  );
                }
              } else {
                displayedMessages.add(
                  _DisplayedMessage(
                    message: group,
                    key: groupKey,
                    followGroupKey: groupKey,
                  ),
                );
              }
            }
            final expirations = displayedMessages
                .map(
                  (entry) => _getExpiration(
                    entry.message,
                    eventSubConfigurationModel,
                    messagesModel,
                  ),
                )
                .toList();
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                RebuildableWidget(
                  rebuildAt: expirations.whereType<DateTime>().toSet(),
                  builder: (context) {
                    final now = DateTime.now();
                    final oneSecondAgo =
                        now.subtract(const Duration(seconds: 1));
                    return ReverseRefreshIndicator(
                      key: _refreshIndicatorKey,
                      onRefresh: () =>
                          MessagesAdapter.instance.subscribe(widget.channel),
                      child: PinnableMessageScrollView(
                        vsync: this,
                        controller: _controller,
                        itemBuilder: (index) {
                          final entry = displayedMessages[index];
                          final message = entry.message;

                          return StyleModelTheme(
                            key: Key(entry.key),
                            child: Builder(
                              builder: (context) {
                                // Suppress redundant subscription events.
                                if (message is TwitchSubscriptionEventModel) {
                                  if (index != displayedMessages.length - 1) {
                                    final next =
                                        displayedMessages[index + 1].message;
                                    if (next
                                            is TwitchSubscriptionMessageEventModel &&
                                        next.subscriberUserName ==
                                            message.subscriberUserName &&
                                        next.tier == message.tier) {
                                      return const SizedBox.shrink();
                                    }
                                  }
                                  if (index > 0) {
                                    final previous =
                                        displayedMessages[index - 1].message;
                                    if (previous
                                            is TwitchSubscriptionMessageEventModel &&
                                        previous.subscriberUserName ==
                                            message.subscriberUserName &&
                                        previous.tier == message.tier) {
                                      return const SizedBox.shrink();
                                    }
                                  }
                                }
                                // in a merged view, actions like shoutouts go to
                                // the channel the message came from.
                                final source = message.channel;
                                final chatMessage = ChatHistoryMessage(
                                  message: message,
                                  channel: source ?? widget.channel,
                                  onFollowExpand: entry.followGroupKey == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _expandedFollowGroups
                                                .add(entry.followGroupKey!);
                                          });
                                        },
                                );
                                final Widget messageWidget =
                                    messagesModel.channels.length > 1 &&
                                            source != null
                                        ? ChannelAttribution(
                                            provider: source.provider,
                                            child: chatMessage,
                                          )
                                        : chatMessage;
                                // Centralized, consistent spacing.
                                final paddedMessage = Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: messageWidget,
                                );
                                final showSeparator = messagesModel.separators
                                    .contains(messages.length - index - 1);
                                // only show separators after the first 50.
                                if (showSeparator && index > 50) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SeparatorWidget(
                                        widget.channel,
                                        message.timestamp,
                                      ),
                                      paddedMessage,
                                    ],
                                  );
                                }
                                return paddedMessage;
                              },
                            ),
                          );
                        },
                        findChildIndexCallback: (key) {
                          return displayedMessages.indexWhere(
                            (entry) => key == Key(entry.key),
                          );
                        },
                        isPinnedBuilder: (index) {
                          final expiration = expirations[index];

                          if (expiration == null ||
                              // if the message is too expired, it can't be pinned again.
                              // note: we track unpinned separately to permit animations.
                              expiration.isBefore(oneSecondAgo)) {
                            return PinState.notPinnable;
                          }
                          return expiration.isAfter(now)
                              ? PinState.pinned
                              : PinState.unpinned;
                        },
                        count: displayedMessages.length,
                      ),
                    );
                  },
                ),
                _ScrollToBottomWidget(
                  show: !_atBottom,
                  onPressed: () async {
                    if (!_controller.hasClients) return;

                    updateScrollPosition();

                    if (_controller.offset < 2500) {
                      await _controller.animateTo(
                        0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // jump instead, it's a better user experience.
                      _controller.jumpTo(0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: dropped == 0 ? 0 : 150,
                    child: dropped == 0
                        ? null
                        : Text(
                            AppLocalizations.of(context)!
                                .newMessageCount(dropped),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                  ),
                ),
              ],
            );
          },
        ),
        const ConnectionStatusWidget(),
      ],
    );
  }
}
