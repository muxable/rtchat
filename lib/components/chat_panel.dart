import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/connection_status.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/components/pinnable/scroll_view.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/message_configuration.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

class RebuildableWidget extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final Set<DateTime> rebuildAt;

  const RebuildableWidget(
      {Key? key, required this.builder, required this.rebuildAt})
      : super(key: key);

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
    super.dispose();

    _clearTimers();
  }

  void _setTimers() {
    final now = DateTime.now();
    timers = widget.rebuildAt.expand((dateTime) sync* {
      final duration = dateTime.difference(now);
      if (!duration.isNegative) {
        yield Timer(duration, () => setState(() {}));
      }
    }).toSet();
  }

  void _clearTimers() {
    for (final timer in timers) {
      timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

DateTime? _getExpiration(
    MessageModel model,
    EventSubConfigurationModel eventSubConfigurationModel,
    TwitchMessageConfig twitchMessageConfig) {
  if (model is TwitchRaidEventModel) {
    final raidEventConfig = eventSubConfigurationModel.raidEventConfig;
    return raidEventConfig.eventDuration > Duration.zero
        ? model.timestamp.add(raidEventConfig.eventDuration)
        : null;
  } else if (model is TwitchHostEventModel) {
    final hostEventConfig = eventSubConfigurationModel.hostEventConfig;
    return hostEventConfig.eventDuration > Duration.zero
        ? model.timestamp.add(hostEventConfig.eventDuration)
        : null;
  } else if (model is TwitchFollowEventModel) {
    final followEventConfig = eventSubConfigurationModel.followEventConfig;
    return followEventConfig.eventDuration > Duration.zero
        ? model.timestamp.add(followEventConfig.eventDuration)
        : null;
  } else if (model is TwitchCheerEventModel) {
    final cheerEventConfig = eventSubConfigurationModel.cheerEventConfig;
    return cheerEventConfig.eventDuration > Duration.zero
        ? model.timestamp.add(cheerEventConfig.eventDuration)
        : null;
  } else if (model is TwitchSubscriptionEventModel ||
      model is TwitchSubscriptionGiftEventModel ||
      model is TwitchSubscriptionMessageEventModel) {
    final subEventConfig = eventSubConfigurationModel.subscriptionEventConfig;
    return subEventConfig.eventDuration > Duration.zero
        ? model.timestamp.add(subEventConfig.eventDuration)
        : null;
  } else if (model is TwitchPollEventModel) {
    final pollEventConfig = eventSubConfigurationModel.pollEventConfig;
    if (model.status == 'archived' || model.status == 'terminated') {
      return null;
    }
    return model.endTimestamp.add(pollEventConfig.eventDuration);
  } else if (model is TwitchChannelPointRedemptionEventModel) {
    final channelPointRedemptionEventConfig =
        eventSubConfigurationModel.channelPointRedemptionEventConfig;
    final unfulfilledDuration =
        channelPointRedemptionEventConfig.eventDuration +
            channelPointRedemptionEventConfig.unfulfilledAdditionalDuration;

    if (model.status == TwitchChannelPointRedemptionStatus.unfulfilled &&
        unfulfilledDuration > Duration.zero) {
      return model.timestamp.add(unfulfilledDuration);
    }
    if (model.status == TwitchChannelPointRedemptionStatus.fulfilled &&
        channelPointRedemptionEventConfig.eventDuration > Duration.zero) {
      return model.timestamp
          .add(channelPointRedemptionEventConfig.eventDuration);
    }
    return null;
  } else if (model is TwitchHypeTrainEventModel) {
    final hypetrainEventConfig =
        eventSubConfigurationModel.hypetrainEventConfig;
    return model.endTimestamp.add(hypetrainEventConfig.eventDuration);
  } else if (model is TwitchPredictionEventModel) {
    final predictionEventConfig =
        eventSubConfigurationModel.predictionEventConfig;

    if (model.status == 'canceled') {
      return null;
    }

    return model.endTime.add(predictionEventConfig.eventDuration);
  } else if (model is TwitchMessageModel) {
    if (model.isModerator) {
      return twitchMessageConfig.modMessageDuration > Duration.zero
          ? model.timestamp.add(twitchMessageConfig.modMessageDuration)
          : null;
    } else if (model.isVip) {
      return twitchMessageConfig.vipMessageDuration > Duration.zero
          ? model.timestamp.add(twitchMessageConfig.vipMessageDuration)
          : null;
    }
    return null;
  }
  return null;
}

class _ScrollToBottomWidget extends StatelessWidget {
  final bool show;
  final void Function() onPressed;

  const _ScrollToBottomWidget(
      {Key? key, required this.show, required this.onPressed})
      : super(key: key);

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
              primary: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: const Icon(Icons.arrow_downward, color: Colors.white)),
      ),
    );
  }
}

class ChatPanelWidget extends StatefulWidget {
  final Channel channel;

  const ChatPanelWidget({required this.channel, Key? key}) : super(key: key);

  @override
  State<ChatPanelWidget> createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget>
    with TickerProviderStateMixin {
  final _controller = ScrollController(keepScrollOffset: true);

  // don't render anything after this message if not null.
  MessageModel? _pauseAt;
  MessageModel? _lastMessage;
  var _atBottom = true;

  @override
  void initState() {
    super.initState();

    _controller.addListener(updateScrollPosition);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void updateScrollPosition() {
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
        Consumer3<MessagesModel, EventSubConfigurationModel,
                TwitchMessageConfig>(
            builder: (context, messagesModel, eventSubConfigurationModel,
                twitchMessageConfig, child) {
          var messages = messagesModel.messages.reversed.toList();
          _lastMessage = messages.isEmpty ? null : messages.first;
          if (messages.isEmpty) {
            return FutureBuilder(
              future: MessagesAdapter.instance.hasMessages(widget.channel),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                if (snapshot.hasData && snapshot.data == false) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'It\'s quiet in here.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            );
          }
          if (_pauseAt != null) {
            final index = messages.indexOf(_pauseAt!);
            if (index != -1) {
              messages = messages.sublist(index);
            }
          }
          final expirations = messages
              .map((message) => _getExpiration(
                  message, eventSubConfigurationModel, twitchMessageConfig))
              .toList();
          return RebuildableWidget(
              rebuildAt: expirations.whereType<DateTime>().toSet(),
              builder: (context) {
                final now = DateTime.now();
                final oneSecondAgo = now.subtract(const Duration(seconds: 1));
                return PinnableMessageScrollView(
                  vsync: this,
                  controller: _controller,
                  itemBuilder: (index) => StyleModelTheme(
                      key: Key(messages[index].messageId),
                      child: ChatHistoryMessage(
                          message: messages[index], channel: widget.channel)),
                  findChildIndexCallback: (key) => messages
                      .indexWhere((element) => key == Key(element.messageId)),
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
                  count: messages.length,
                );
              });
        }),
        _ScrollToBottomWidget(
          show: !_atBottom,
          onPressed: () {
            updateScrollPosition();
            _controller.animateTo(0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut);
          },
        ),
        const ConnectionStatusWidget(),
      ],
    );
  }
}
