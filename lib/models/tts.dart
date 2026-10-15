import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

/// Looks up the language [channel] streams in, as its platform reports it
/// (e.g. `es`, `other`), or null if it isn't known.
typedef StreamLanguageLookup = Future<String?> Function(Channel channel);

/// Reads the language from the channel's metadata document, once: `first`
/// opens a Firestore listener and closes it after the first snapshot.
Future<String?> _lookUpStreamLanguage(Channel channel) async {
  final metadata = await ChannelsAdapter.instance
      .forChannel(channel)
      .first
      .timeout(const Duration(seconds: 20));
  return metadata is StreamChannelMetadata ? metadata.language : null;
}

class TtsModel extends ChangeNotifier {
  final TtsEngine _engine;

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
  // language of the channel they came from: their stream language, looked
  // up once per channel while it's shown.
  final Map<Channel, Language> _channelLanguages = {};
  // when each shown channel's language was last looked up (or is being
  // looked up), so channels aren't looked up again on every views change.
  final Map<Channel, DateTime> _languageLookedUpAt = {};
  List<Channel> _channels = const [];
  Channel? _primaryChannel;
  final StreamLanguageLookup _lookUpLanguage;
  final DateTime Function() _now;
  var _isDisposed = false;

  /// How long until a channel whose language couldn't be found (no metadata
  /// yet, offline, an error) is looked up again.
  static const languageRetryInterval = Duration(minutes: 5);
  // this is used to ignore messages in the past.
  var _lastMessageTime = DateTime.now();
  MessageModel? _activeMessage;
  var _isSubscribersOnly = false;

  /// Follows the channels shown, to read each message in its channel's
  /// stream language. Called on every [ViewsModel] change, so it only looks
  /// up channels it doesn't know the language of yet: each once, and those
  /// it couldn't find again after [languageRetryInterval]. Nothing here
  /// changes the saved [language].
  void update(ViewsModel model) {
    final channels = model.channels;
    _channels = channels;
    _primaryChannel = model.primaryChannel;
    _channelLanguages.removeWhere((channel, _) => !channels.contains(channel));
    _languageLookedUpAt
        .removeWhere((channel, _) => !channels.contains(channel));
    for (final channel in channels) {
      _lookUpLanguageOf(channel);
    }
  }

  void _lookUpLanguageOf(Channel channel) {
    if (_channelLanguages.containsKey(channel)) {
      return;
    }
    final now = _now();
    final last = _languageLookedUpAt[channel];
    if (last != null && now.difference(last) < languageRetryInterval) {
      return;
    }
    _languageLookedUpAt[channel] = now;
    Future.sync(() => _lookUpLanguage(channel)).then((code) {
      final language = streamLanguage(code);
      // the channel may have been closed in the meantime.
      if (_isDisposed || language == null || !_channels.contains(channel)) {
        return;
      }
      _channelLanguages[channel] = language;
    }, onError: (Object error) {
      // e.g. offline: the channel's language stays unknown for now.
      debugPrint('no stream language for $channel: $error');
    });
  }

  /// The language to read a stream's chat in, from the language its
  /// platform reports: null when it's unknown, including `other` and `asl`
  /// (sign language), which say nothing about the spoken language.
  static Language? streamLanguage(String? code) {
    final trimmed = code?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == 'other' ||
        trimmed == 'asl') {
      return null;
    }
    return Language(trimmed.toLowerCase());
  }

  /// The stream language of [model]'s channel (or of the first channel
  /// shown, for messages without one), if known: looked up, else as it was
  /// when the channel was found (e.g. in search).
  Language? _knownLanguageFor(MessageModel model) {
    final channel = model.channel ?? _primaryChannel;
    if (channel == null) {
      return null;
    }
    return _channelLanguages[channel] ?? streamLanguage(channel.language);
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

  /// The language to read chat in when its channel's stream language isn't
  /// known. Saved with the settings; the stream languages never change it.
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

  /// The language to read [model] in: its channel's stream language, if
  /// known, else [language].
  Language languageFor(MessageModel model) =>
      _knownLanguageFor(model) ?? _language;

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
      FirebaseCrashlytics.instance.recordError(e, st);
    } finally {
      _activeMessage = null;
      completer.complete();
      _pending.remove(model.messageId);
    }
  }

  Future<void> _speak(MessageModel model, String vocalization) async {
    _activeMessage = model;

    if ((_mode != TtsMode.disabled || model is SystemMessageModel) &&
        _pending.containsKey(model.messageId)) {
      try {
        // chat is in its channel's language, when known; otherwise, and for
        // alerts (in the app's language), the voice keeps its default.
        final language = model is ChatMessage ? _knownLanguageFor(model) : null;
        await _engine.speak(vocalization,
            rate: _speed, pitch: _pitch, language: language?.languageCode);
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st);
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
    _engine.stop().catchError((_) {});
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

  /// Speaks through [engine], or through the platform's voices by default.
  /// [lookUpStreamLanguage] finds a channel's stream language, from its
  /// Firestore metadata by default; [clock] tells the time for retrying
  /// lookups.
  TtsModel.fromJson(Map<String, dynamic> json,
      {TtsEngine? engine,
      StreamLanguageLookup? lookUpStreamLanguage,
      DateTime Function()? clock})
      : _engine = engine ?? SystemTtsEngine(),
        _lookUpLanguage = lookUpStreamLanguage ?? _lookUpStreamLanguage,
        _now = clock ?? DateTime.now {
    _updateFromJsonInternal(json);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _engine.dispose().catchError((_) {});
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
