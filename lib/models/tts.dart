import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/auxiliary/realtimecash.dart';
import 'package:rtchat/models/messages/auxiliary/streamelements.dart';
import 'package:rtchat/models/messages/auxiliary/streamlabs.dart';
import 'package:rtchat/models/messages/chat.dart';
import 'package:rtchat/models/messages/kick/event.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/channel_point_redemption_event.dart';
import 'package:rtchat/models/messages/twitch/event.dart';
import 'package:rtchat/models/messages/twitch/hype_train_event.dart';
import 'package:rtchat/models/messages/twitch/prediction_event.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_create_event.dart';
import 'package:rtchat/models/messages/twitch/shoutout_receive_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_gift_event.dart';
import 'package:rtchat/models/messages/twitch/subscription_message_event.dart';
import 'package:rtchat/models/tts/language.dart';
import 'package:rtchat/models/tts/muted_user.dart';
import 'package:rtchat/models/views.dart';

enum TtsMode { disabled, alertsOnly, enabled }

final _markup = RegExp(r'</?b>');

/// Records an error that didn't stop speech, e.g. to Crashlytics.
typedef TtsErrorReporter = void Function(Object error, StackTrace stack);

void _recordToCrashlytics(Object error, StackTrace stack) {
  FirebaseCrashlytics.instance.recordError(error, stack);
}

class TtsModel extends ChangeNotifier {
  /// Speaks with the platform's voices, and whenever [_neuralEngine] fails.
  final TtsEngine _systemEngine;
  TtsEngine? _neuralEngine;
  // neural engines that were replaced, disposed between utterances.
  final List<TtsEngine> _retiredEngines = [];
  final TtsErrorReporter _reportError;

  Future<void> _previousUtterance = Future.value();
  // the messages waiting to be read out, and the channel they came from.
  final Map<String, Channel?> _pending = {};

  // past these many queued messages tts drops the author prelude, and then
  // turns itself off.
  static const _preludeBacklog = 10;
  static const _maxBacklog = 20;
  var _language = Language();
  var _isRandomVoiceEnabled = true;
  var _isBotMuted = false;
  var _isEmoteMuted = false;
  var _isPreludeMuted = false;
  var _speed = Platform.isAndroid ? 0.8 : 0.395;
  var _pitch = 1.0;
  var _mode = TtsMode.disabled;
  final List<MutedUser> _mutedUsers = [];
  // languages of the channels being watched, for reading messages in the
  // language of the channel they came from.
  final Map<Channel, Language> _channelLanguages = {};
  // this is used to ignore messages in the past.
  var _lastMessageTime = DateTime.now();
  MessageModel? _activeMessage;
  var _isSubscribersOnly = false;

  void update(ViewsModel model) async {
    if (kDebugMode) {
      _updateChannelLanguages(model.channels);
      final channel = model.primaryChannel;
      if (channel == null) {
        _language = Language();
        return;
      }

      // channels without a metadata document yet have no language.
      final metadata = await ChannelsAdapter.instance.forChannel(channel).first;
      final streamLanguage =
          metadata is StreamChannelMetadata ? metadata.language : null;
      final isSupported = streamLanguage != null &&
          streamLanguage != 'other' &&
          streamLanguage != 'asl';
      language = isSupported ? Language(streamLanguage) : Language();
      notifyListeners();
    }
  }

  Future<void> _updateChannelLanguages(List<Channel> channels) async {
    _channelLanguages.removeWhere((channel, _) => !channels.contains(channel));
    for (final channel in channels) {
      final metadata = await ChannelsAdapter.instance.forChannel(channel).first;
      final language =
          metadata is StreamChannelMetadata ? metadata.language : null;
      if (language != null && language != 'other' && language != 'asl') {
        _channelLanguages[channel] = Language(language);
      }
    }
  }

  String getVocalization(AppLocalizations l10n, MessageModel model,
      {bool includeAuthorPrelude = false}) {
    if (model is ChatMessage) {
      final text = model.tokenized
          .where((token) =>
              token is TextToken ||
              (!_isEmoteMuted && token is EmoteToken) ||
              token is UserMentionToken ||
              token is LinkToken)
          .map((token) {
        if (token is TextToken) {
          return token.text;
        } else if (token is EmoteToken) {
          return token.code;
        } else if (token is UserMentionToken) {
          return token.username.replaceAll("_", " ");
        } else if (token is LinkToken) {
          return token.url.host;
        }
      }).join("");
      if (text.trim().isEmpty) {
        return "";
      }
      final author = model.author.displayName ?? model.author.login;
      if (!includeAuthorPrelude || isPreludeMuted) {
        return text;
      }
      return model.isAction
          ? l10n.actionMessage(author, text)
          : l10n.saidMessage(author, text);
    }
    // event strings mark up names with <b> for display; don't read it aloud.
    return _eventVocalization(l10n, model).replaceAll(_markup, "");
  }

  String _eventVocalization(AppLocalizations l10n, MessageModel model) {
    if (model is KickFollowEventModel) {
      return l10n.followingEvent(model.follower.name);
    } else if (model is KickSubscriptionEventModel) {
      return model.isRenewal
          ? l10n.kickResubscriptionEvent(model.subscriber.name, model.months)
          : l10n.kickSubscriptionEvent(model.subscriber.name);
    } else if (model is KickGiftedSubscriptionsEventModel) {
      return l10n.kickGiftedSubscriptionsEvent(
          model.gifter?.name ?? l10n.anonymous, model.giftees.length);
    } else if (model is KicksGiftedEventModel) {
      return l10n.kicksGiftedEvent(model.sender.name, model.amount);
    } else if (model is StreamStateEventModel) {
      final timestamp = model.timestamp;
      return model.isOnline
          ? l10n.streamOnline(timestamp, timestamp)
          : l10n.streamOffline(timestamp, timestamp);
    } else if (model is SystemMessageModel) {
      return model.text;
    } else if (model is TwitchRaidEventModel) {
      return l10n.raidEventMessage(model.from.displayName ?? "", model.viewers);
    } else if (model is TwitchSubscriptionEventModel) {
      return l10n.subscriptionEvent(
          model.subscriberUserName, model.tier.replaceAll("000", ""));
    } else if (model is TwitchSubscriptionGiftEventModel) {
      return l10n.subscriptionGiftEvent(model.gifterUserName, model.total,
          model.tier.replaceAll("000", ""), model.cumulativeTotal);
    } else if (model is TwitchSubscriptionMessageEventModel) {
      return model.localizedText(l10n);
    } else if (model is TwitchFollowEventModel) {
      return l10n.followingEvent(
          model.followers.first.displayName ?? model.followers.first.login);
    } else if (model is TwitchCheerEventModel) {
    } else if (model is TwitchPollEventModel) {
    } else if (model is TwitchChannelPointRedemptionEventModel) {
    } else if (model is TwitchHypeTrainEventModel) {
    } else if (model is TwitchPredictionEventModel) {
    } else if (model is TwitchHostEventModel) {
    } else if (model is TwitchRaidingEventModel) {
    } else if (model is ChatClearedEventModel) {
    } else if (model is StreamlabsDonationEventModel) {
    } else if (model is StreamElementsTipEventModel) {
    } else if (model is SimpleRealtimeCashDonationEventModel) {
    } else if (model is TwitchShoutoutCreateEventModel) {
    } else if (model is TwitchShoutoutReceiveEventModel) {}
    return "";
  }

  bool get isSubscribersOnly {
    return _isSubscribersOnly;
  }

  set isSubscribersOnly(bool value) {
    _isSubscribersOnly = value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  TtsMode get mode {
    return _mode;
  }

  void toggleMode(AppLocalizations localizations) {
    switch (_mode) {
      case TtsMode.disabled:
        setMode(localizations, TtsMode.enabled); // TODO: enable alerts tts
        break;
      case TtsMode.alertsOnly:
        setMode(localizations, TtsMode.enabled);
        break;
      case TtsMode.enabled:
        setMode(localizations, TtsMode.disabled);
        break;
    }
  }

  void setMode(AppLocalizations localizations, TtsMode mode) {
    if (_mode == mode) {
      return;
    }
    _mode = mode;
    switch (mode) {
      case TtsMode.alertsOnly:
        say(localizations,
            SystemMessageModel(text: localizations.alertsEnabled),
            force: true);
        break;
      case TtsMode.enabled:
        say(localizations,
            SystemMessageModel(text: localizations.textToSpeechEnabled),
            force: true);
        break;
      case TtsMode.disabled:
        say(localizations,
            SystemMessageModel(text: localizations.textToSpeechDisabled),
            force: true);
        break;
    }
    _lastMessageTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Language get language {
    return _language;
  }

  set language(Language language) {
    _language = language;
    notifyListeners();
  }

  bool get isRandomVoiceEnabled {
    return _isRandomVoiceEnabled;
  }

  set isRandomVoiceEnabled(bool value) {
    _isRandomVoiceEnabled = value;
    notifyListeners();
  }

  bool get isBotMuted {
    return _isBotMuted;
  }

  set isBotMuted(bool value) {
    _isBotMuted = value;
    notifyListeners();
  }

  bool get isEmoteMuted {
    return _isEmoteMuted;
  }

  set isEmoteMuted(bool value) {
    _isEmoteMuted = value;
    notifyListeners();
  }

  bool get isPreludeMuted {
    return _isPreludeMuted;
  }

  set isPreludeMuted(bool value) {
    _isPreludeMuted = value;
    notifyListeners();
  }

  double get speed {
    return _speed;
  }

  set speed(double value) {
    _speed = value;
    notifyListeners();
  }

  double get pitch {
    return _pitch;
  }

  set pitch(double value) {
    _pitch = value;
    notifyListeners();
  }

  // match on provider and login: logins are stable and always present,
  // unlike display names, and the same login on another provider is someone
  // else.
  bool isMuted(ChatUser user) =>
      _mutedUsers.any((muted) => muted.matches(user));

  void mute(ChatUser user) {
    if (isMuted(user)) {
      return;
    }
    _mutedUsers.add(MutedUser.from(user));
    notifyListeners();
  }

  void unmute(ChatUser user) {
    final count = _mutedUsers.length;
    _mutedUsers.removeWhere((muted) => muted.matches(user));
    if (_mutedUsers.length != count) {
      notifyListeners();
    }
  }

  @visibleForTesting
  void setChannelLanguage(Channel channel, Language language) =>
      _channelLanguages[channel] = language;

  /// The language to read [model] in: its channel's, if known.
  Language languageFor(MessageModel model) {
    final channel = model.channel;
    return (channel == null ? null : _channelLanguages[channel]) ?? _language;
  }

  void say(AppLocalizations localizations, MessageModel model,
      {bool force = false}) async {
    if (_mode == TtsMode.disabled && !force) {
      return;
    }

    if (_mode == TtsMode.alertsOnly && model is ChatMessage) {
      return;
    }

    if (model is ChatMessage) {
      if (_isSubscribersOnly && !model.isSubscriber) {
        return;
      }

      if (isMuted(model.author)) {
        return;
      }

      if ((_isBotMuted && model.author.isBot) || model.isCommand) {
        return;
      }
    }

    // make sure the message is in the future.
    if (model is SystemMessageModel) {
      if (model.timestamp.isBefore(_lastMessageTime)) {
        return;
      }
      _lastMessageTime = model.timestamp;
    }

    // chat is outpacing speech: give up rather than fall ever further behind.
    if (_pending.length >= _maxBacklog && model is! SystemMessageModel) {
      _turnOffForBacklog(localizations);
      return;
    }

    final activeMessage = _activeMessage;
    var includeAuthorPrelude = true;
    if (activeMessage is ChatMessage && model is ChatMessage) {
      includeAuthorPrelude =
          !(activeMessage.author.provider == model.author.provider &&
              activeMessage.author.userId == model.author.userId);
    }

    // skip "X said" to catch up on a long backlog.
    if (_pending.length >= _preludeBacklog) {
      includeAuthorPrelude = false;
    }

    final vocalization = getVocalization(
      localizations,
      model,
      includeAuthorPrelude: includeAuthorPrelude,
    );

    // if the vocalization is empty, skip the message
    if (vocalization.isEmpty) {
      return;
    }

    final previous = _previousUtterance;
    final completer = Completer();

    _previousUtterance = completer.future;
    _pending[model.messageId] = model.channel;

    // always release the queue: a failed utterance (e.g. a platform error)
    // would otherwise block, and hold on to, every message after it.
    try {
      await previous;
      await _speak(model, vocalization);
    } catch (e, st) {
      _reportError(e, st);
    } finally {
      _activeMessage = null;
      completer.complete();
      _pending.remove(model.messageId);
    }
  }

  Future<void> _speak(MessageModel model, String vocalization) async {
    _activeMessage = model;

    bool shouldSpeak() =>
        (_mode != TtsMode.disabled || model is SystemMessageModel) &&
        _pending.containsKey(model.messageId);

    if (!shouldSpeak()) {
      return;
    }
    // nothing is speaking between utterances, so a replaced engine can go
    // without cutting anyone off.
    await _disposeRetiredEngines();

    final language = languageFor(model).languageCode;
    final neural = _neuralEngine;
    if (neural != null) {
      try {
        await neural.speak(vocalization,
            rate: _speed, pitch: _pitch, language: language);
        return;
      } catch (e, st) {
        _reportError(e, st);
      }
      // read this message with the system voice rather than drop it, unless
      // it was cut off in the meantime.
      if (!shouldSpeak()) {
        return;
      }
    }
    try {
      await _systemEngine.speak(vocalization,
          rate: _speed, pitch: _pitch, language: language);
    } catch (e, st) {
      _reportError(e, st);
    }
  }

  /// The engine that speaks with a neural voice pack, or null to speak with
  /// the platform's voices. When it fails, the message is read with the
  /// platform's voices instead.
  TtsEngine? get neuralEngine => _neuralEngine;

  /// Replaces the neural engine; the model owns [engine] from now on. The
  /// message being read finishes with the old engine, which is then
  /// disposed before the next message starts, so the two never overlap.
  set neuralEngine(TtsEngine? engine) {
    final previous = _neuralEngine;
    if (identical(previous, engine)) {
      return;
    }
    _neuralEngine = engine;
    if (previous == null) {
      return;
    }
    _retiredEngines.add(previous);
    // queue the disposal like an utterance, in case nothing else is queued.
    final queue = _previousUtterance;
    final completer = Completer<void>();
    _previousUtterance = completer.future;
    queue
        .then((_) => _disposeRetiredEngines())
        .whenComplete(completer.complete);
  }

  Future<void> _disposeRetiredEngines() async {
    final engines = List.of(_retiredEngines);
    _retiredEngines.clear();
    for (final engine in engines) {
      try {
        await engine.dispose();
      } catch (e, st) {
        _reportError(e, st);
      }
    }
  }

  void _turnOffForBacklog(AppLocalizations localizations) {
    _pending.clear();
    _mode = TtsMode.disabled;
    say(localizations,
        SystemMessageModel(text: localizations.textToSpeechTooManyMessages),
        force: true);
    // cut off the current utterance; everything queued behind it is dropped.
    _neuralEngine?.stop().catchError((_) {});
    _systemEngine.stop().catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void unsay(String messageId) {
    _pending.remove(messageId);
  }

  void stop() {
    _pending.clear();
  }

  /// Stops reading out the messages that came from [channel].
  void stopChannel(Channel channel) {
    _pending.removeWhere((_, pending) => pending == channel);
  }

  void updateFromJson(Map<String, dynamic> json) {
    _updateFromJsonInternal(json);
    notifyListeners();
  }

  void _updateFromJsonInternal(Map<String, dynamic> json) {
    if (json['isBotMuted'] != null) {
      _isBotMuted = json['isBotMuted'];
    }
    if (json['pitch'] != null) {
      _pitch = json['pitch'];
    }
    if (json['speed'] != null) {
      _speed = json['speed'];
    }
    if (json['isEmoteMuted'] != null) {
      _isEmoteMuted = json['isEmoteMuted'];
    }
    if (json['isPreludeMuted'] != null) {
      _isPreludeMuted = json['isPreludeMuted'];
    }
    if (json['isRandomVoiceEnabled'] != null) {
      _isRandomVoiceEnabled = json['isRandomVoiceEnabled'];
    }
    if (json['language'] != null) {
      _language = Language(json['language']);
    }
    final userJson = json['mutedUsers'];
    if (userJson != null) {
      // the saved list is a full snapshot, so it replaces the current one.
      _mutedUsers
        ..clear()
        ..addAll([
          for (var user in userJson)
            MutedUser.fromJson(Map<String, dynamic>.from(user)),
        ]);
    }
  }

  /// Speaks through [engine], or through the platform's voices by default,
  /// until a [neuralEngine] is set. Errors that don't stop speech go to
  /// [reportError], Crashlytics by default.
  TtsModel.fromJson(Map<String, dynamic> json,
      {TtsEngine? engine, TtsErrorReporter? reportError})
      : _systemEngine = engine ?? SystemTtsEngine(),
        _reportError = reportError ?? _recordToCrashlytics {
    _updateFromJsonInternal(json);
  }

  @override
  void dispose() {
    for (final engine in [
      _systemEngine,
      if (_neuralEngine != null) _neuralEngine!,
      ..._retiredEngines,
    ]) {
      engine.dispose().catchError((_) {});
    }
    _neuralEngine = null;
    _retiredEngines.clear();
    super.dispose();
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": isBotMuted,
        "isEmoteMuted": isEmoteMuted,
        "isPreludeMuted": isPreludeMuted,
        "isRandomVoiceEnabled": isRandomVoiceEnabled,
        "language": language.languageCode,
        "pitch": pitch,
        "speed": speed,
        'mutedUsers': _mutedUsers.map((e) => e.toJson()).toList(),
      };
}
