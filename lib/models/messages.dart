import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/main.dart';
import 'package:rtchat/models/adapters/messages.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';

class MessagesModel extends ChangeNotifier {
  final List<StreamSubscription<void>> _subscriptions = [];

  @visibleForTesting
  Stream<DeltaEvent> Function(Channel channel) forChannel =
      (channel) => MessagesAdapter.instance.forChannel(channel);
  List<ChannelEvent> _events = [];
  List<MessageModel> _messages = [];
  Set<int> _separators = {};
  Function()? onMessagePing;
  List<Channel> _channels = const [];
  // channels whose initial history has loaded, so new events are live.
  final Set<Channel> _liveChannels = {};

  // it's a bit odd to have this here, but tts only cares about the delta events
  // so it's easier to wire this way.
  TtsModel? _tts;

  set channel(Channel? channel) =>
      channels = channel == null ? const [] : [channel];

  /// The channels whose messages are merged into [messages].
  set channels(List<Channel> channels) {
    // ignore if no update
    if (listEquals(channels, _channels)) {
      return;
    }
    _channels = List.unmodifiable(channels);
    _messages = [];
    _separators = {};
    _events = [];
    _liveChannels.clear();
    if (_tts != null) {
      final localizations = _getLocalizations();
      if (localizations != null) {
        _tts!.setMode(localizations, TtsMode.disabled);
      } else {
        debugPrint("Localizations not available");
      }
    }
    notifyListeners();

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    for (final channel in _channels) {
      _subscriptions
          .add(forChannel(channel).listen((event) => _onEvent(channel, event)));
    }
  }

  List<Channel> get channels => _channels;

  void _onEvent(Channel channel, DeltaEvent event) {
    _events.add((channel: channel, event: event));
    _messages = applyDeltaEvent(
      _messages,
      event,
      channel: _channels.length > 1 ? channel : null,
      onAppend: (model) {
        // Pass localizations to the TTS say method
        final localizations = _getLocalizations();
        if (localizations != null) {
          _tts?.say(localizations, model);
        } else {
          debugPrint("Localizations not available");
        }
        if (_liveChannels.contains(channel) && shouldPing()) {
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
        // stop reading out messages as soon as they're deleted.
        if (updated is ChatMessage && updated.deleted) {
          _tts?.unsay(updated.messageId);
        }
      },
    );
    if (event is AppendDeltaEvent || event is ClearDeltaEvent) {
      _separators = computeSeparators(_messages);
    }
    if (event is ClearDeltaEvent) {
      _tts?.stop();
    } else if (event is LiveStateDeltaEvent) {
      _liveChannels.add(channel);
    }
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void dispose() {
    // the listener would otherwise keep notifying (and holding on to) a
    // disposed model.
    _disposed = true;
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  List<MessageModel> get messages => _messages;

  Set<int> get separators => _separators;

  /// Whether every channel has loaded its history and is receiving new
  /// messages.
  bool get isLive =>
      _channels.isNotEmpty && _channels.every(_liveChannels.contains);

  Set<ChatUser> get authors {
    return _messages
        .whereType<ChatMessage>()
        .map((model) => model.author)
        .toSet();
  }

  /// Loads older messages for every channel, each from before the oldest
  /// event received from it.
  Future<void> pullMoreMessages() async {
    final futureEvents = _events; // this prevents a race.
    final history = <ChannelEvent>[];
    for (final channel in _channels) {
      final oldest = futureEvents
          .where((entry) => entry.channel == channel)
          .map((entry) => entry.event.timestamp)
          .firstOrNull;
      if (oldest == null) {
        continue;
      }
      final events =
          await MessagesAdapter.instance.forChannelHistory(channel, oldest);
      history.addAll(events.map((event) => (channel: channel, event: event)));
    }
    if (history.isEmpty || _disposed) {
      return;
    }
    _events = [...history, ...futureEvents];
    _messages = _channels.length > 1
        ? replayEvents(_events)
        : _events.fold(
            [], (messages, entry) => applyDeltaEvent(messages, entry.event));
    _separators = computeSeparators(_messages);
    notifyListeners();
  }

  void pruneMessages() {
    // this doesn't need to notify because it has no impact on the UI
    if (_messages.length > 1000) {
      _messages.removeRange(0, _messages.length - 1000);
      _events.removeWhere(
          (entry) => entry.event.timestamp.isBefore(_messages.first.timestamp));
      _separators = computeSeparators(_messages);
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
///
/// When messages from several channels are merged, [channel] is the channel
/// [event] came from: clearing chat and user-wide updates (bans) then only
/// affect that channel's messages.
@visibleForTesting
List<MessageModel> applyDeltaEvent(
  List<MessageModel> messages,
  DeltaEvent event, {
  Channel? channel,
  void Function(MessageModel model)? onAppend,
  void Function(DeltaEvent event, MessageModel previous, MessageModel updated)?
      onUpdate,
}) {
  if (event is AppendDeltaEvent) {
    if (_insert(messages, event.model)) {
      onAppend?.call(event.model);
    }
  } else if (event is UpdateDeltaEvent) {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (message.messageId == event.messageId) {
        final updated = event.update(message)..channel ??= message.channel;
        messages[i] = updated;
        onUpdate?.call(event, message, updated);
        break;
      }
    }
  } else if (event is UpdateAllDeltaEvent) {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      if (channel != null && message.channel != channel) {
        continue;
      }
      final updated = event.update(message)..channel ??= message.channel;
      onUpdate?.call(event, message, updated);
      messages[i] = updated;
    }
  } else if (event is ClearDeltaEvent) {
    final cleared = ChatClearedEventModel(
      messageId: event.messageId,
      timestamp: event.timestamp,
    )..channel = channel;
    if (channel == null) {
      return [cleared];
    }
    // other channels' chat is unaffected.
    final remaining =
        messages.where((message) => message.channel != channel).toList();
    _insert(remaining, cleared);
    return remaining;
  }
  return messages;
}

/// Inserts [model] in timestamp order, returning whether it was appended to
/// the end (as opposed to arriving out of order).
bool _insert(List<MessageModel> messages, MessageModel model) {
  // check if this event comes after the last message
  if (messages.isNotEmpty &&
      model.timestamp.isBefore(messages.last.timestamp)) {
    // this message is out of order, so we need to insert it in the right place
    final index = messages
        .indexWhere((element) => element.timestamp.isAfter(model.timestamp));
    messages.insert(index, model);
    return false;
  }
  messages.add(model);
  return true;
}

/// An event and the channel it was received on.
typedef ChannelEvent = ({Channel channel, DeltaEvent event});

/// Rebuilds the merged message list from [events], applied in timestamp order
/// (keeping the received order for events with the same timestamp).
@visibleForTesting
List<MessageModel> replayEvents(List<ChannelEvent> events) {
  final ordered = events.indexed.toList()
    ..sort((a, b) {
      final byTime = a.$2.event.timestamp.compareTo(b.$2.event.timestamp);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  var messages = <MessageModel>[];
  for (final (_, entry) in ordered) {
    messages = applyDeltaEvent(messages, entry.event, channel: entry.channel);
  }
  return messages;
}

/// Returns the indices of [messages] that should be preceded by a separator.
///
/// The first message always gets one; after that a separator is added at least
/// every 50 messages (on a chat message) and wherever more than 5 minutes
/// elapsed since the previous message. Recomputing from the list keeps indices
/// correct after out-of-order inserts, history loads and pruning.
@visibleForTesting
Set<int> computeSeparators(List<MessageModel> messages) {
  final separators = <int>{};
  var last = 0;
  for (var i = 0; i < messages.length; i++) {
    if (i == 0) {
      separators.add(0);
      continue;
    }
    final model = messages[i];
    if (i + 1 - last >= 50 && model is ChatMessage) {
      separators.add(i);
      last = i;
    }
    if (model.timestamp.difference(messages[i - 1].timestamp).inMinutes > 5) {
      separators.add(i);
      last = i;
    }
  }
  return separators;
}
