import 'package:flutter/material.dart';
import 'package:rtchat/models/chat_history.dart';
import 'package:rtchat/models/messages/tts.dart';

class TtsModel extends ChangeNotifier {
  TtsAudioHandler ttsHandler;

  Future<void> handleDeltaEvent(DeltaEvent event) async {
    if (event is AppendDeltaEvent) {
      final mediaItem = TtsMediaItem.fromMessageModel(event.model);
      if (mediaItem != null) {
        await ttsHandler.addQueueItem(mediaItem);
      }
    } else if (event is UpdateDeltaEvent) {
      for (var i = 0; i < ttsHandler.queue.value.length; i++) {
        final existingItem = ttsHandler.queue.value[i];
        if (existingItem.id == event.messageId) {
          final updated = event.update((existingItem as TtsMediaItem).model);
          final mediaItem = TtsMediaItem.fromMessageModel(updated);
          if (mediaItem != null) {
            await ttsHandler.setQueueItem(i, mediaItem);
          }
        }
      }
    }
  }

  Future<void> clearQueue() async {
    await ttsHandler.updateQueue([]);
  }

  List<TtsMediaItem> get queue {
    return ttsHandler.queue.value as List<TtsMediaItem>;
  }

  Future<void> force(String message) => ttsHandler.force(message);

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
