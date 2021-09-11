import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/messages/tts_audio_handler.dart';

class TtsModel extends ChangeNotifier {
  TtsAudioHandler ttsHandler;
  Set<String> blacklist = {};

  set messages(List<MessageModel> messages) {
    // for tts, we sort of cheat a bit and just append the new messages to the end of the list.
    final queue = ttsHandler.queue.value;
    final index = queue.isNotEmpty
        ? messages
            .lastIndexWhere((message) => message.messageId == queue.last.id)
        : -1;
    final mediaItems = messages
        .sublist(index + 1)
        .map((message) => TtsMediaItem.fromMessageModel(message))
        .whereType<TtsMediaItem>()
        .toList();
    if (index == -1) {
      // looks like we wiped the history, so reset the queue.
      enabled = false;
      ttsHandler.updateQueue(mediaItems);
    } else {
      ttsHandler.addQueueItems(mediaItems);
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

  void addNameToBlacklist(String name) {
    blacklist.add(name);
    ttsHandler.blackList = blacklist;
    notifyListeners();
  }

  void removeNameFromBlacklist(String name) {
    if (blacklist.isNotEmpty && blacklist.contains(name)) {
      blacklist.remove(name);
      ttsHandler.blackList = blacklist;
      notifyListeners();
    }
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
    final blacklist = json['blacklist'];
    if (blacklist != null) {
      for (String item in blacklist) {
        blacklist.add(item);
      }
    }
  }

  Map<String, dynamic> toJson() => {
        "isBotMuted": isBotMuted,
        "isEmoteMuted": isEmoteMuted,
        "pitch": pitch,
        "speed": speed,
        'blacklist': blacklist
      };
}
