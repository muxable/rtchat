import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

final validateUrl = Uri.https('id.twitch.tv', '/oauth2/validate');

const twitchClientId = "edfnh2q85za8phifif9jxt3ey6t9b9";

class TtsMessage extends MediaItem {
  final String messageId;
  final TwitchUserModel author;
  final String? coalescingHeader;
  final String message;
  final bool hasEmote;
  final Map<String, dynamic> emotes;

  TtsMessage(
      {required this.messageId,
      required this.author,
      required this.message,
      this.coalescingHeader,
      required this.hasEmote,
      Map<String, dynamic>? emotes})
      : emotes = emotes ?? const {},
        super(id: messageId, artist: author.display, title: message);

  String get spokenMessage {
    if (message.trim().isEmpty) {
      return "";
    }
    if (coalescingHeader != null) {
      return "$coalescingHeader $message".replaceAll("_", " ");
    }
    return message.replaceAll("_", " ");
  }

  static List _parseEmotes(Map<String, dynamic> emotes) {
    var ranges = [];
    for (MapEntry e in emotes.entries) {
      for (final str in e.value) {
        final pair = str.split('-');
        final start = int.parse(pair[0]);
        final end = int.parse(pair[1]);
        ranges.add([start, end]);
      }
    }

    ranges.sort((a, b) => a[0].compareTo(b[0]));
    return ranges;
  }

  String get spokenNoEmotesMessage {
    var ranges = _parseEmotes(emotes);
    var res = coalescingHeader == null ? "" : "$coalescingHeader ";
    var index = 0;
    for (var i = 0; i < ranges.length; i++) {
      var start = ranges[i][0];
      var end = ranges[i][1];
      if (start > index) {
        res += message.substring(index, start);
      }
      index = end + 1;
    }

    if (index < message.length) {
      res += message.substring(index);
    }
    if (res.trim() == coalescingHeader) {
      return "";
    }
    return res.replaceAll("_", " ");
  }
}

class TtsAudioHandler extends BaseAudioHandler with QueueHandler {
  final FlutterTts _tts = FlutterTts();
  var isBotMuted = false;
  var isEmoteMuted = false;
  var speed = 1.0;
  var pitch = 1.0;

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

    final message = queue.value[index] as TtsMessage;
    if (fromAutoplay && isBotMuted && message.author.isBot) {
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
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    if (isEmoteMuted) {
      await _tts.speak(message.spokenNoEmotesMessage);
    } else {
      await _tts.speak(message.spokenMessage);
    }
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
      await play();
    }
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

  Future<void> force(TtsMessage message) async {
    await skipToEnd();
    await _tts.setSpeechRate(speed);
    await _tts.setPitch(pitch);
    await _tts.speak(message.spokenMessage);
  }
}

class TtsModel extends ChangeNotifier {
  TtsAudioHandler ttsHandler;

  Future<void> speak(TtsMessage message) => ttsHandler.addQueueItem(message);

  Future<void> force(TtsMessage message) => ttsHandler.force(message);

  bool get enabled {
    return ttsHandler.enabled;
  }

  set enabled(bool value) {
    ttsHandler.enabled = value;
    notifyListeners();
  }

  bool get isBotMuted => ttsHandler.isBotMuted;

  set isBotMuted(bool value) {
    ttsHandler.isBotMuted = value;
    notifyListeners();
  }

  double get speed => ttsHandler.speed;

  set speed(double value) {
    ttsHandler.speed = value;
    notifyListeners();
  }

  double get pitch => ttsHandler.pitch;

  set pitch(double value) {
    ttsHandler.pitch = value;
    notifyListeners();
  }

  bool get isEmoteMuted => ttsHandler.isEmoteMuted;

  set isEmoteMuted(bool value) {
    ttsHandler.isEmoteMuted = value;
    notifyListeners();
  }

  TtsModel.fromJson(this.ttsHandler, Map<String, dynamic> json) {
    if (json['isBotMuted'] != null) {
      ttsHandler.isBotMuted = json['isBotMuted'];
    }
    if (json['pitch'] != null) {
      ttsHandler.pitch = json['pitch'];
    }
    if (json['speed'] != null) {
      ttsHandler.speed = json['speed'];
    }
    if (json['isEmoteMuted'] != null) {
      ttsHandler.isEmoteMuted = json['isEmoteMuted'];
    }
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": isBotMuted,
        "isEmoteMuted": isEmoteMuted,
        "pitch": pitch,
        "speed": speed,
      };
}
