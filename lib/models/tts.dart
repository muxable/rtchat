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

void _recordToCrashlytics(Object error, StackTrace stack) {
  FirebaseCrashlytics.instance.recordError(error, stack);
}

/// Why [TtsModel] reads everything with the platform's voices for the rest
/// of the session, although a neural voice pack is installed.
enum NeuralTtsFallback {
  /// The model failed to load, e.g. the device ran out of memory.
  loadFailed,

  /// The device has too little memory to load a model without risking the
  /// app (or the streaming app next to it); see
  /// [DeviceMemory.isTooSmallForNeuralTts].
  lowMemoryDevice,
}

/// Reads chat and alerts aloud, one message at a time.
///
/// Each message is read, in this order of preference:
///
/// 1. by a neural engine (an installed voice pack) that speaks the
///    message's language, with the voice the user chose for that language
///    or, for chat with [isRandomVoiceEnabled], the chatter's own voice
///    (see [voiceKey]). [neuralEngines] are tried in order, through a
///    [VoiceRouter];
/// 2. if no neural engine speaks the language, by the platform's voices
///    (`SystemTtsEngine`), told the language when it is known;
/// 3. if the neural engine fails, by the platform's voices too, for that
///    message only (unless it was unsaid in the meantime).
///
/// Chat is read in its channel's language ([languageFor]). Alerts and
/// system messages are read in the language of the app's strings they are
/// made of, always with the chosen (not a chatter's) voice.
///
/// Neural models take a few hundred megabytes, so they don't stay loaded
/// when they aren't needed ([releaseNeuralModels]): once text to speech is
/// turned off, after [neuralIdleTimeout] without speech, and on memory
/// pressure (called by a `MemoryPressureMonitor`). The next message loads
/// the model again. If a model fails to load, every message is read with the
/// platform's voices for the rest of the session ([neuralFallback]).
class TtsModel extends ChangeNotifier {
  /// How long neural models stay loaded without speech by default.
  ///
  /// Reloading takes about a second (see `doc/native_contract.md` in
  /// on_device_tts), a delay that goes unnoticed after a quiet spell of
  /// chat, while a loaded model holds 300 to 600 MB that the streaming app
  /// next to us may need.
  static const defaultNeuralIdleTimeout = Duration(minutes: 5);

  /// Speaks with the platform's voices: messages in languages no neural
  /// engine speaks, and those a neural engine fails to.
  final TtsEngine _systemEngine;
  List<TtsEngine> _neuralEngines = const [];
  VoiceRouter _router = VoiceRouter.empty;
  // neural engines that were replaced, disposed between utterances.
  final List<TtsEngine> _retiredEngines = [];
  // the neural voice chosen for each language, by voice id, keyed by the
  // normalized language tag (see [_voiceKeyFor]).
  final Map<String, String> _neuralVoices = {};
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
  var _isVoicePackSuggestionDismissed = false;

  /// How long neural models stay loaded without speech; see
  /// [defaultNeuralIdleTimeout].
  final Duration neuralIdleTimeout;
  Timer? _idleTimer;
  // whether a neural engine spoke since the models were last released.
  var _isNeuralInUse = false;
  // releases of the neural models; speech waits for them.
  Future<void> _releasing = Future.value();
  // a release asked for while a message was being read, done after it.
  Completer<void>? _releaseAfterUtterance;
  NeuralTtsFallback? _neuralFallback;
  var _isNeuralFallbackNoticePending = false;

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

  /// [channel]'s stream language, if known: looked up, else as it was when
  /// the channel was found (e.g. in search).
  Language? _knownLanguageOf(Channel? channel) {
    if (channel == null) {
      return null;
    }
    return _channelLanguages[channel] ?? streamLanguage(channel.language);
  }

  /// The language of the first channel shown, if known; chat without a
  /// known language is read in [language].
  Language? get primaryStreamLanguage => _knownLanguageOf(_primaryChannel);

  /// The language most chat is read in: the first channel's stream
  /// language if known, else [language].
  Language get readingLanguage => primaryStreamLanguage ?? _language;

  /// The stream language of [model]'s channel (or of the first channel
  /// shown, for messages without one), if known.
  Language? _knownLanguageFor(MessageModel model) =>
      _knownLanguageOf(model.channel ?? _primaryChannel);

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
        _releaseNeuralModelsWhenOff();
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

  /// The language to read [model] in, and the one to tell the platform's
  /// voices (null keeps their default). Chat is in its channel's language;
  /// the platform's voices are only told it when the channel's language is
  /// known, so they keep the device's language otherwise. Alerts and system
  /// messages are made of the app's strings, so they are in its language.
  ({String language, String? systemLanguage}) _speechLanguageFor(
      AppLocalizations localizations, MessageModel model) {
    if (model is ChatMessage) {
      return (
        language: languageFor(model).languageCode,
        systemLanguage: _knownLanguageFor(model)?.languageCode,
      );
    }
    final appLanguage = localizations.localeName.replaceAll('_', '-');
    return (language: appLanguage, systemLanguage: appLanguage);
  }

  /// Identifies [user] for picking their voice: their provider and user id,
  /// or login if there's no id. Hashed with [fnv1a32], so a chatter keeps
  /// their voice across restarts and platforms.
  static String voiceKey(ChatUser user) => user.userId.isNotEmpty
      ? '${user.provider}:${user.userId}'
      : '${user.provider}:login:${user.login.toLowerCase()}';

  static String _voiceKeyFor(String language) =>
      LanguageTag.parse(language).toString();

  /// The id of the voice chosen for [language] (or, failing that, for
  /// [routed], the engine's own tag for it, or the bare language), if any.
  String? _chosenVoiceId(String language, [String? routed]) =>
      _neuralVoices[_voiceKeyFor(language)] ??
      (routed == null ? null : _neuralVoices[_voiceKeyFor(routed)]) ??
      _neuralVoices[LanguageTag.parse(language).language];

  /// The neural voices that can read [language], a BCP-47 tag, or none if
  /// no installed voice pack speaks it (it's then read with the platform's
  /// voices).
  Future<List<TtsVoice>> availableVoices(String language) async =>
      (await _router.route(language))?.voices ?? const [];

  /// The neural voice that reads [language] when [isRandomVoiceEnabled] is
  /// off, and that reads alerts: the one set with [setVoice] if it's still
  /// available, else the first voice (e.g. `F1`). Null if no installed voice
  /// pack speaks [language].
  Future<TtsVoice?> voiceFor(String language) async {
    final route = await _router.route(language);
    return route?.voiceWithId(_chosenVoiceId(language, route.language));
  }

  /// Reads [language] with the neural voice [voiceId] (a [TtsVoice.id] from
  /// [availableVoices]) from now on, unless [isRandomVoiceEnabled] picks a
  /// voice per chatter.
  void setVoice(String language, String voiceId) {
    _neuralVoices[_voiceKeyFor(language)] = voiceId;
    notifyListeners();
  }

  /// Every language the neural voices speak, as the engines' own tags
  /// (e.g. `en`, `pt`), without repeats; none without a voice pack.
  Future<List<String>> neuralLanguages() => _router.languages();

  /// Reads [text], a sample in [language], with the neural voice [voiceId],
  /// after whatever is being read now. Does nothing if no neural engine
  /// speaks [language]. Throws if the engine fails, so the caller can say
  /// so.
  Future<void> previewVoice(
      String language, String voiceId, String text) async {
    final route = await _router.route(language);
    if (route == null) {
      return;
    }
    final previous = _previousUtterance;
    final completer = Completer<void>();
    _previousUtterance = completer.future;
    try {
      await previous;
      await route.engine.speak(text,
          voice: route.voiceWithId(voiceId),
          rate: _speed,
          pitch: _pitch,
          language: route.language);
    } finally {
      completer.complete();
    }
  }

  /// Whether the suggestion to download a voice pack was dismissed.
  bool get isVoicePackSuggestionDismissed => _isVoicePackSuggestionDismissed;

  set isVoicePackSuggestionDismissed(bool value) {
    _isVoicePackSuggestionDismissed = value;
    notifyListeners();
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
    final language = _speechLanguageFor(localizations, model);

    // if the vocalization is empty, skip the message
    if (vocalization.isEmpty) {
      return;
    }

    final previous = _previousUtterance;
    final completer = Completer();

    _previousUtterance = completer.future;
    _pending[model.messageId] = model.channel;
    _idleTimer?.cancel();

    // always release the queue: a failed utterance (e.g. a platform error)
    // would otherwise block, and hold on to, every message after it.
    try {
      await previous;
      await _speak(model, vocalization,
          language: language.language, systemLanguage: language.systemLanguage);
    } catch (e, st) {
      _reportError(e, st);
    } finally {
      _activeMessage = null;
      final release = _releaseAfterUtterance;
      if (release != null) {
        _releaseAfterUtterance = null;
        _releaseNeuralModelsNow().whenComplete(release.complete);
      }
      completer.complete();
      _pending.remove(model.messageId);
      if (_pending.isEmpty && _isNeuralInUse) {
        _idleTimer?.cancel();
        _idleTimer = Timer(neuralIdleTimeout, () {
          if (_pending.isEmpty) releaseNeuralModels();
        });
      }
    }
  }

  /// Reads [vocalization] in [language] with a neural engine, else with the
  /// platform's voices in [systemLanguage]; see [TtsModel] for the order.
  Future<void> _speak(MessageModel model, String vocalization,
      {required String language, String? systemLanguage}) async {
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
    // a model being unloaded can't speak; the engine loads it again.
    await _releasing;

    // 1. a neural engine that speaks the language, unless the models can't
    // load on this device.
    final route =
        _neuralFallback == null ? await _router.route(language) : null;
    if (route != null) {
      if (!shouldSpeak()) {
        return;
      }
      final author = model is ChatMessage ? model.author : null;
      final voice = author != null && _isRandomVoiceEnabled
          ? route.voiceForKey(voiceKey(author))
          : route.voiceWithId(_chosenVoiceId(language, route.language));
      try {
        _isNeuralInUse = true;
        await route.engine.speak(vocalization,
            voice: voice,
            rate: _speed,
            pitch: _pitch,
            language: route.language);
        return;
      } on NeuralTtsLoadException catch (e, st) {
        _reportError(e, st);
        fallBackToSystemVoices(NeuralTtsFallback.loadFailed);
      } catch (e, st) {
        _reportError(e, st);
      }
      // 3. read this message with the system voice rather than drop it,
      // unless it was cut off in the meantime.
      if (!shouldSpeak()) {
        return;
      }
    }
    // 2. no neural engine speaks the language (or 3., it failed).
    try {
      await _systemEngine.speak(vocalization,
          rate: _speed, pitch: _pitch, language: systemLanguage);
    } catch (e, st) {
      _reportError(e, st);
    }
  }

  /// The engines that speak with neural voice packs, in order of
  /// preference: each message goes to the first that speaks its language
  /// (see [VoiceRouter]), else to the platform's voices. When one fails, the
  /// message is read with the platform's voices instead.
  List<TtsEngine> get neuralEngines => _neuralEngines;

  /// Replaces the neural engines; the model owns them from now on. Engines
  /// that stay keep their loaded models. The message being read finishes
  /// with its engine; engines that went are then disposed before the next
  /// message starts, so two never overlap.
  set neuralEngines(List<TtsEngine> engines) {
    final previous = _neuralEngines;
    if (listEquals(previous, engines)) {
      return;
    }
    _neuralEngines = List.unmodifiable(engines);
    _router = VoiceRouter(_neuralEngines, onError: _reportError);
    // other packs may load where the old ones didn't.
    if (_neuralFallback == NeuralTtsFallback.loadFailed) {
      _neuralFallback = null;
      _isNeuralFallbackNoticePending = false;
    }
    // the voices and languages on offer changed.
    notifyListeners();
    final removed = [
      for (final engine in previous)
        if (!engines.any((e) => identical(e, engine))) engine,
    ];
    if (removed.isEmpty) {
      return;
    }
    _retiredEngines.addAll(removed);
    // queue the disposal like an utterance, in case nothing else is queued.
    final queue = _previousUtterance;
    final completer = Completer<void>();
    _previousUtterance = completer.future;
    queue
        .then((_) => _disposeRetiredEngines())
        .whenComplete(completer.complete);
  }

  /// The first of [neuralEngines], if any.
  TtsEngine? get neuralEngine => _neuralEngines.firstOrNull;

  /// Makes [engine] the only neural engine, or removes them all when null;
  /// see [neuralEngines].
  set neuralEngine(TtsEngine? engine) =>
      neuralEngines = engine == null ? const [] : [engine];

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

  /// Why every message is read with the platform's voices for the rest of
  /// the session although neural voices are installed, or null if they
  /// aren't (or they work).
  NeuralTtsFallback? get neuralFallback => _neuralFallback;

  /// Whether the user should be told, once, about [neuralFallback]; the UI
  /// calls [acknowledgeNeuralFallback] once it has.
  // TODO(#1506): show a one-time notice in the TTS settings / chat screen.
  bool get isNeuralFallbackNoticePending => _isNeuralFallbackNoticePending;

  void acknowledgeNeuralFallback() {
    if (!_isNeuralFallbackNoticePending) return;
    _isNeuralFallbackNoticePending = false;
    notifyListeners();
  }

  /// Reads everything with the platform's voices for the rest of the
  /// session (until the neural engines change, for
  /// [NeuralTtsFallback.loadFailed]) and frees the neural models.
  void fallBackToSystemVoices(NeuralTtsFallback reason) {
    if (_neuralFallback != null) return;
    _neuralFallback = reason;
    _isNeuralFallbackNoticePending = true;
    releaseNeuralModels();
    notifyListeners();
  }

  /// Frees the neural engines' models (see [TtsEngine.release]); the next
  /// message they read loads them again. A message being read finishes
  /// first, so nothing is cut off. Called on memory pressure; also when
  /// text to speech is turned off, and after [neuralIdleTimeout] without
  /// speech.
  Future<void> releaseNeuralModels() {
    _idleTimer?.cancel();
    if (_activeMessage != null) {
      return (_releaseAfterUtterance ??= Completer<void>()).future;
    }
    return _releaseNeuralModelsNow();
  }

  Future<void> _releaseNeuralModelsNow() {
    _isNeuralInUse = false;
    final engines = [..._neuralEngines];
    return _releasing = _releasing.then((_) async {
      for (final engine in engines) {
        try {
          await engine.release();
        } catch (e, st) {
          _reportError(e, st);
        }
      }
    });
  }

  /// Once what is queued (e.g. "text to speech disabled") has been read,
  /// releases the neural models if text to speech is still off.
  void _releaseNeuralModelsWhenOff() {
    final queue = _previousUtterance;
    final completer = Completer<void>();
    _previousUtterance = completer.future;
    queue.then((_) {
      if (_mode == TtsMode.disabled) return releaseNeuralModels();
    }).whenComplete(completer.complete);
  }

  void _turnOffForBacklog(AppLocalizations localizations) {
    _pending.clear();
    _mode = TtsMode.disabled;
    say(localizations,
        SystemMessageModel(text: localizations.textToSpeechTooManyMessages),
        force: true);
    _releaseNeuralModelsWhenOff();
    // cut off the current utterance; everything queued behind it is dropped.
    for (final engine in [..._neuralEngines, _systemEngine]) {
      engine.stop().catchError((_) {});
    }
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
    if (json['isVoicePackSuggestionDismissed'] != null) {
      _isVoicePackSuggestionDismissed = json['isVoicePackSuggestionDismissed'];
    }
    // the `voice` key of versions with cloud tts held cloud voice names
    // (e.g. fr-FR-Wavenet-A), which mean nothing to neural voices: it's
    // ignored, and dropped on the next save.
    final voicesJson = json['neuralVoices'];
    if (voicesJson is Map) {
      // the saved map is a full snapshot, so it replaces the current one.
      _neuralVoices
        ..clear()
        ..addAll({
          for (final MapEntry(:key, :value) in voicesJson.entries)
            if (key is String && value is String) _voiceKeyFor(key): value,
        });
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
  /// [reportError], Crashlytics by default. [lookUpStreamLanguage] finds
  /// a channel's stream language, from its Firestore metadata by default;
  /// [clock] tells the time for retrying lookups.
  TtsModel.fromJson(Map<String, dynamic> json,
      {TtsEngine? engine,
      TtsErrorReporter? reportError,
      StreamLanguageLookup? lookUpStreamLanguage,
      DateTime Function()? clock,
      this.neuralIdleTimeout = defaultNeuralIdleTimeout})
      : _systemEngine = engine ?? SystemTtsEngine(),
        _reportError = reportError ?? _recordToCrashlytics,
        _lookUpLanguage = lookUpStreamLanguage ?? _lookUpStreamLanguage,
        _now = clock ?? DateTime.now {
    _updateFromJsonInternal(json);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _idleTimer?.cancel();
    for (final engine in [
      _systemEngine,
      ..._neuralEngines,
      ..._retiredEngines,
    ]) {
      engine.dispose().catchError((_) {});
    }
    _neuralEngines = const [];
    _router = VoiceRouter.empty;
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
        "neuralVoices": Map.of(_neuralVoices),
        "isVoicePackSuggestionDismissed": isVoicePackSuggestionDismissed,
        'mutedUsers': _mutedUsers.map((e) => e.toJson()).toList(),
      };
}
