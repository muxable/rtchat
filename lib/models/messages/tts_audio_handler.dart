import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

class TtsMediaItem extends MediaItem {
  final bool isBot;
  final bool isCommand;
  final MessageModel model;

  static TtsMediaItem? fromMessageModel(MessageModel model) {
    if (model is TwitchMessageModel) {
      return TtsMediaItem._(
        model,
        messageId: model.messageId,
        author: model.author.display,
        message: model.tokenized.join(""),
        isBot: model.author.isBot,
        isCommand: model.isCommand,
      );
    } else if (model is StreamStateEventModel) {
      return TtsMediaItem._(
        model,
        messageId: model.messageId,
        author: "RealtimeChat",
        message: model.isOnline ? "Stream is online" : "Stream is offline",
      );
    }
  }

  TtsMediaItem._(this.model,
      {required String messageId,
      required String author,
      required String message,
      this.isBot = false,
      this.isCommand = false})
      : super(id: messageId, artist: author, title: message);

  String getVocalization({required bool emotes}) {
    final model = this.model;
    if (model is TwitchMessageModel) {
      final text = model.tokenized
          .where((token) =>
              token is TextToken ||
              (emotes && token is EmoteToken) ||
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
      return model.isAction ? "$author $text" : "$author said $text";
    } else if (model is StreamStateEventModel) {
      return model.isOnline ? "Stream is online" : "Stream is offline";
    }
    return "";
  }
}

class TtsAudioHandler extends BaseAudioHandler {
  final FlutterTts _tts = FlutterTts();
  var isBotMuted = false;
  var isEmoteMuted = false;
  var speed = 1.0;
  var pitch = 1.0;
  final Set<TwitchUserModel> mutedUsers = {};

  final List<TtsMediaItem> messages = [];
  var index = 0;

  var isPlaying = false;
  // when the user explicitly chooses to seek forward/backward through the history,
  // autoplay is disabled.
  var isSeeking = false;
  var isEnabled = false;

  TtsAudioHandler() {
    _tts.setCompletionHandler(() async {
      if (index < messages.length - 1) {
        index++;
        await play(fromAutoplay: true);
      } else {
        await stop();
      }
    });
  }

  @override
  Future<void> play({bool fromAutoplay = false}) async {
    isSeeking = false;
    isPlaying = true;
    updateMediaControls();

    final message = messages[index];
    bool hasMutedUser = false;
    if (message.model is TwitchMessageModel) {
      final m = message.model as TwitchMessageModel;
      hasMutedUser = mutedUsers.contains(m.author);
    }

    if (fromAutoplay &&
        ((isBotMuted && message.isBot) || message.isCommand || hasMutedUser)) {
      if (index < messages.length - 1) {
        index++;
        await play(fromAutoplay: true);
      } else {
        await stop();
      }
      return;
    }
    final vocalization = message.getVocalization(emotes: !isEmoteMuted);
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    await _tts.speak(vocalization);
  }

  @override
  Future<void> stop() async {
    isSeeking = false;
    isPlaying = false;
    updateMediaControls();

    await _tts.stop();
  }

  @override
  Future<void> fastForward() async {
    isSeeking = true;
    await stop();
    if (index < messages.length - 1) {
      index++;
    }
    updateMediaControls();
  }

  set enabled(bool enabled) {
    isEnabled = enabled;
    if (enabled) {
      index = messages.length - 1;
      updateMediaControls();
    } else {
      stop();
    }
  }

  bool get enabled => isEnabled;

  @override
  Future<void> rewind() async {
    isSeeking = true;
    index = max(0, index - 1);
    await stop();
    updateMediaControls();
  }

  @override
  Future<void> skipToPrevious() async {
    // this might come from a media button. basically if this happens,
    // immediately play the previous message.
    index = max(0, index - 1);
    await play();
    updateMediaControls();
  }

  @override
  Future<void> skipToNext() async {
    // this is actually skip to end.
    isSeeking = false;
    index = messages.length - 1;
    await stop();
    updateMediaControls();
  }

  Future<void> add(List<TtsMediaItem> mediaItems) async {
    messages.addAll(mediaItems);
    if (enabled && !isSeeking && !isPlaying) {
      index = messages.length - mediaItems.length;
      updateMediaControls();
      await play(fromAutoplay: true);
    }
  }

  Future<void> set(List<TtsMediaItem> mediaItems) async {
    messages
      ..clear()
      ..addAll(mediaItems);
    if (enabled && !isSeeking && !isPlaying) {
      index = messages.length - 1;
      updateMediaControls();
    }
  }

  Future<void> force(String message) async {
    index = messages.length;
    updateMediaControls();
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    await _tts.speak(message);
  }

  void updateMediaControls() {
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.rewind,
        isPlaying ? MediaControl.stop : MediaControl.play,
        MediaControl.fastForward,
        MediaControl.skipToNext
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: isEnabled,
      queueIndex: 0,
    ));
    if (messages.isNotEmpty) {
      mediaItem.add(messages[index]);
    } else {
      mediaItem.add(null);
    }
  }
}
