import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/tts.dart';

class MessagesModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  List<DeltaEvent> _events = [];
  List<MessageModel> _messages = [];
  Set<int> _separators = {};
  Function()? onMessagePing;
  bool _isLive = false;
  Channel? _channel;

  // it's a bit odd to have this here, but tts only cares about the delta events
  // so it's easier to wire this way.
  TtsModel? _tts;

  set channel(Channel? channel) {
    // ignore if no update
    if (channel == _channel) {
      return;
    }
    _channel = channel;
    _messages = [];
    _separators = {};
    _events = [];
    _isLive = false;
    if (_tts != null) {
      final localizations = _getLocalizations();
      if (localizations != null) {
        _tts!.setMode(localizations, TtsMode.disabled);
      } else {
        debugPrint("Localizations not available");
      }
    }
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription =
          MessagesAdapter.instance.forChannel(channel).listen((event) {
        _events.add(event);
        _messages = applyDeltaEvent(
          _messages,
          event,
          onAppend: (model) {
            // Pass localizations to the TTS say method
            final localizations = _getLocalizations();
            if (localizations != null) {
              _tts?.say(localizations, model);
            } else {
              debugPrint("Localizations not available");
            }
            if (_isLive && shouldPing()) {
              ProfilesAdapter.instance
                  .getIsOnline(channelId: channel.toString())
                  .first
                  .then((value) {
                if (value) {
                  onMessagePing?.call();
                }
              });
            }
          },
          onUpdate: (event, previous, updated) {
            final message = event is UpdateAllDeltaEvent ? updated : previous;
            if (message is TwitchMessageModel && message.deleted) {
              _tts?.unsay(message.messageId);
            }
          },
        );
        if (event is AppendDeltaEvent) {
          updateSeparators(_messages, _separators, event.model);
        } else if (event is ClearDeltaEvent) {
          _separators = {};
          _tts?.stop();
        } else if (event is LiveStateDeltaEvent) {
          _isLive = true;
        }
        notifyListeners();
      });
    }
  }

  List<MessageModel> get messages => _messages;

  Set<int> get separators => _separators;

  bool get isLive => _isLive;

  Set<TwitchUserModel> get authors {
    return _messages
        .whereType<TwitchMessageModel>()
        .map((model) => model.author)
        .toSet();
  }

  Future<void> pullMoreMessages() async {
    final channel = _channel;
    if (channel == null) {
      return;
    }
    final futureEvents = _events; // this prevents a race.
    final events = await MessagesAdapter.instance
        .forChannelHistory(channel, _events.first.timestamp);
    if (events.isEmpty) {
      return;
    }
    List<MessageModel> messages = []; // rebuild a new message set.
    _events = [...events, ...futureEvents];
    for (final event in _events) {
      // reproduce the message set
      messages = applyDeltaEvent(messages, event);
    }
    _messages = messages;
    notifyListeners();
  }

  void pruneMessages() {
    // this doesn't need to notify because it has no impact on the UI
    if (_messages.length > 1000) {
      _messages.removeRange(0, _messages.length - 1000);
      _events.removeWhere(
          (element) => element.timestamp.isBefore(_messages.first.timestamp));
    }
  }

  set tts(TtsModel? tts) {
    // ignore if no update
    if (tts == _tts) {
      return;
    }
    _tts = tts;
    if (_tts != null) {
      final localizations = _getLocalizations();
      if (localizations != null) {
        _tts!.setMode(localizations, TtsMode.disabled);
      } else {
        debugPrint("Localizations not available");
      }
    }
    notifyListeners();
  }

  TtsModel? get tts => _tts;

  Duration _announcementPinDuration = const Duration(seconds: 10);

  set announcementPinDuration(Duration duration) {
    _announcementPinDuration = duration;
    notifyListeners();
  }

  Duration get announcementPinDuration => _announcementPinDuration;

  Duration _pingMinGapDuration = const Duration(days: 10000);

  set pingMinGapDuration(Duration duration) {
    _pingMinGapDuration = duration;
    notifyListeners();
  }

  Duration get pingMinGapDuration => _pingMinGapDuration;

  bool shouldPing() {
    if (messages.isEmpty) {
      return false;
    }
    if (messages.length == 1) {
      return messages.last.timestamp
          .isAfter(DateTime.now().subtract(const Duration(seconds: 1)));
    }
    final lastMessage = messages.last;
    final secondLastMessage = messages[messages.length - 2];
    final delta = lastMessage.timestamp.difference(secondLastMessage.timestamp);
    return delta.compareTo(_pingMinGapDuration) > 0;
  }

  MessagesModel.fromJson(Map<String, dynamic> json) {
    if (json['announcementPinDuration'] != null) {
      _announcementPinDuration =
          Duration(seconds: json['announcementPinDuration'].toInt());
    }
    if (json['pingMinGapDuration'] != null) {
      _pingMinGapDuration =
          Duration(seconds: json['pingMinGapDuration'].toInt());
    }
  }

  Map<String, dynamic> toJson() => {
        "announcementPinDuration": _announcementPinDuration.inSeconds.toInt(),
        "pingMinGapDuration": _pingMinGapDuration.inSeconds.toInt(),
      };

  BuildContext? _getContext() {
    return navigatorKey.currentContext;
  }

  AppLocalizations? _getLocalizations() {
    final context = _getContext();
    if (context != null) {
      return AppLocalizations.of(context);
    }
    return null;
  }
}

/// Applies [event] to [messages] in place and returns the resulting list, which
/// is a new list if the event clears the chat.
///
/// [onAppend] is called when a message is appended to the end of the list, but
/// not when an out-of-order message is inserted. [onUpdate] is called for each
/// message replaced by an [UpdateDeltaEvent] or [UpdateAllDeltaEvent].
@visibleForTesting
List<MessageModel> applyDeltaEvent(
  List<MessageModel> messages,
  DeltaEvent event, {
  void Function(MessageModel model)? onAppend,
  void Function(DeltaEvent event, MessageModel previous, MessageModel updated)?
      onUpdate,
}) {
  if (event is AppendDeltaEvent) {
    // check if this event comes after the last message
    if (messages.isNotEmpty &&
        event.model.timestamp.isBefore(messages.last.timestamp)) {
      // this message is out of order, so we need to insert it in the right place
      final index = messages.indexWhere(
          (element) => element.timestamp.isAfter(event.model.timestamp));
      messages.insert(index, event.model);
    } else {
      messages.add(event.model);
      onAppend?.call(event.model);
    }
  } else if (event is UpdateDeltaEvent) {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.messageId == event.messageId) {
        final updated = event.update(message);
        messages[i] = updated;
        onUpdate?.call(event, message, updated);
        break;
      }
    }
  } else if (event is UpdateAllDeltaEvent) {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final updated = event.update(message);
      onUpdate?.call(event, message, updated);
      messages[i] = updated;
    }
  } else if (event is ClearDeltaEvent) {
    return [
      ChatClearedEventModel(
        messageId: event.messageId,
        timestamp: event.timestamp,
      )
    ];
  }
  return messages;
}

/// Adds a separator to [separators] if needed after [model] was added to
/// [messages].
@visibleForTesting
void updateSeparators(
    List<MessageModel> messages, Set<int> separators, MessageModel model) {
  // check to see if we should add a separator
  // always add if it's the first message.
  if (messages.length == 1) {
    separators.add(0);
  } else {
    final lastSeparator = separators.isEmpty ? 0 : separators.reduce(max);
    // add if the last separator was at least 50 away and this was a
    // chat message.
    if (messages.length - lastSeparator >= 50 && model is TwitchMessageModel) {
      separators.add(messages.length - 1);
    }
    // add if the difference between this message and the last message
    // is more than 5 minutes.
    final cmp = messages[messages.length - 2];
    if (model.timestamp.difference(cmp.timestamp).inMinutes > 5) {
      separators.add(messages.length - 1);
    }
  }
}
