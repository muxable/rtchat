import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/components/pinnable/scroll_view.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';

class _RebuildableWidget extends StatefulWidget {
  final Widget Function(BuildContext) builder;
  final Set<DateTime> rebuildAt;

  const _RebuildableWidget(
      {Key? key, required this.builder, required this.rebuildAt})
      : super(key: key);

  @override
  _RebuildableWidgetState createState() => _RebuildableWidgetState();
}

class _RebuildableWidgetState extends State<_RebuildableWidget> {
  Set<Timer> timers = {};

  @override
  void initState() {
    super.initState();

    _setTimers();
  }

  @override
  void didUpdateWidget(_RebuildableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _clearTimers();
    _setTimers();
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
    MessageModel model, EventSubConfigurationModel eventSubConfigurationModel) {
  if (model is TwitchRaidEventModel) {
    return model.timestamp.add(const Duration(seconds: 15));
  } else if (model is TwitchFollowEventModel) {
    final followEventConfig = eventSubConfigurationModel.followEventConfig;
    return followEventConfig.isEventPinnable
        ? model.timestamp.add(followEventConfig.eventDuration)
        : null;
  } else if (model is TwitchCheerEventModel) {
    final cheerEventConfig = eventSubConfigurationModel.cheerEventConfig;
    return cheerEventConfig.isEventPinnable
        ? model.timestamp.add(cheerEventConfig.eventDuration)
        : null;
  } else if (model is TwitchSubscriptionEventModel ||
      model is TwitchSubscriptionGiftEventModel ||
      model is TwitchSubscriptionMessageEventModel) {
    final subEventConfig = eventSubConfigurationModel.subscriptionEventConfig;
    return subEventConfig.isEventPinnable
        ? model.timestamp.add(subEventConfig.eventDuration)
        : null;
  }
}

class ChatPanelWidget extends StatefulWidget {
  final void Function(bool)? onScrollback;

  const ChatPanelWidget({Key? key, this.onScrollback}) : super(key: key);

  @override
  _ChatPanelWidgetState createState() => _ChatPanelWidgetState();
}

class _ChatPanelWidgetState extends State<ChatPanelWidget>
    with TickerProviderStateMixin {
  final _controller = ScrollController(keepScrollOffset: true);
  var _atBottom = true;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final value = _controller.position.atEdge && _controller.offset == 0;
      if (_atBottom != value) {
        setState(() {
          _atBottom = value;
        });
        if (widget.onScrollback != null) {
          widget.onScrollback!(!_atBottom);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Consumer<ChannelsModel>(builder: (context, model, child) {
        return Consumer<EventSubConfigurationModel>(
            builder: (context, eventSubConfigurationModel, child) {
          final messages = model.messages.reversed.toList();
          final expirations = messages
              .map((message) =>
                  _getExpiration(message, eventSubConfigurationModel))
              .toList();
          return _RebuildableWidget(
              rebuildAt: expirations.whereType<DateTime>().toSet(),
              builder: (context) {
                final now = DateTime.now();
                return PinnableMessageScrollView(
                  vsync: this,
                  controller: _controller,
                  itemBuilder: (index) => StyleModelTheme(
                    child: ChatHistoryMessage(message: messages[index]),
                  ),
                  isPinnedBuilder: (index) {
                    final expiration = expirations[index];
                    if (expiration != null) {
                      return expiration.isAfter(now);
                    }
                  },
                  count: messages.length,
                );
              });
        });
      }),
      Builder(builder: (context) {
        if (_atBottom) {
          return Container();
        }
        return Container(
          alignment: Alignment.bottomCenter,
          child: TextButton(
              onPressed: () {
                _controller.animateTo(0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut);
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Colors.black.withOpacity(0.6)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.only(left: 16, right: 16)),
              ),
              child: const Text("Scroll to bottom")),
        );
      }),
    ]);
  }
}
