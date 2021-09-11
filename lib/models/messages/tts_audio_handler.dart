import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tokens.dart';
import 'package:rtchat/models/messages/twitch/message.dart';

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

class TtsAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  var isBotMuted = false;
  var isEmoteMuted = false;
  var speed = 1.0;
  var pitch = 1.0;
  Set<String> blackList = {};

  var isPlaying = false;
  // when the user explicitly chooses to seek forward/backward through the history,
  // autoplay is disabled.
  var isSeeking = false;

  TtsAudioHandler() {
    _tts.setCompletionHandler(() async {
      final index = playbackState.value.queueIndex;
      if (index != null && index < queue.value.length - 1) {
        await fastForward();
        await play(fromAutoplay: true);
      } else {
        await stop();
      }
    });

    playbackState.add(PlaybackState(
      controls: const [
        MediaControl.rewind,
        MediaControl.play,
        MediaControl.fastForward,
      ],
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.ready,
      playing: false,
      queueIndex: 0,
    ));
  }

  @override
  Future<void> play({bool fromAutoplay = false}) async {
    isSeeking = false;
    isPlaying = true;
    final index = playbackState.value.queueIndex;
    if (index == null) {
      return;
    }

    final message = queue.value[index] as TtsMediaItem;
    final author = message.artist; // author
    print('blacklist: $blackList');

    if (fromAutoplay &&
        ((isBotMuted && message.isBot) ||
            message.isCommand ||
            blackList.contains(author))) {
      if (index < queue.value.length - 1) {
        await fastForward();
        await play(fromAutoplay: true);
      } else {
        await stop();
      }
      return;
    }
    playbackState.add(playbackState.value.copyWith(controls: const [
      MediaControl.rewind,
      MediaControl.stop,
      MediaControl.fastForward,
      MediaControl.skipToNext,
    ]));
    final vocalization = message.getVocalization(emotes: !isEmoteMuted);
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    await _tts.speak(vocalization);
  }

  @override
  Future<void> stop() async {
    isSeeking = false;
    isPlaying = false;
    playbackState.add(playbackState.value.copyWith(controls: const [
      MediaControl.rewind,
      MediaControl.play,
      MediaControl.fastForward,
      MediaControl.skipToNext
    ]));
    await _tts.stop();
  }

  @override
  Future<void> fastForward() async {
    isSeeking = true;
    await stop();
    super.skipToNext();
  }

  set enabled(bool enabled) {
    playbackState.add(playbackState.value.copyWith(playing: enabled));
    if (enabled) {
      skipToEnd();
    } else {
      stop();
    }
  }

  bool get enabled => playbackState.value.playing;

  @override
  Future<void> rewind() async {
    isSeeking = true;
    await stop();
    super.skipToPrevious();
  }

  @override
  Future<void> skipToPrevious() async {
    // this might come from a media button. basically if this happens,
    // immediately play the previous message.
    super.skipToPrevious();
    await play();
  }

  @override
  Future<void> skipToNext() async {
    isSeeking = false;
    await skipToEnd();
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await super.addQueueItem(mediaItem);
    if (enabled && !isSeeking && !isPlaying) {
      await skipToEnd();
      await play(fromAutoplay: true);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await super.addQueueItems(mediaItems);
    if (enabled && !isSeeking && !isPlaying) {
      await skipToEnd();
      await play(fromAutoplay: true);
    }
  }

  Future<void> setQueueItem(int index, MediaItem mediaItem) async {
    queue.add(queue.value..setAll(index, [mediaItem]));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) {
      return;
    }
    playbackState.add(playbackState.value.copyWith(queueIndex: index));
    mediaItem.add(queue.value[index]);
    await super.skipToQueueItem(index);
  }

  Future<void> skipToEnd() async {
    await stop();
    await skipToQueueItem(queue.value.length - 1);
  }

  Future<void> force(String message) async {
    await skipToEnd();
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    await _tts.speak(message);
  }
}
