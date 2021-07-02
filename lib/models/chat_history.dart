import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/message.dart';
import 'package:rtchat/models/tts.dart';

class ChatHistoryModel extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _subscription;

  final List<MessageModel> _messages = [];

  final TtsModel _ttsModule;

  ChatHistoryModel(this._ttsModule);

  Future<void> subscribe(Set<Channel> channels) async {
    final subscribe = FirebaseFunctions.instance.httpsCallable('subscribe');
    channels.forEach((channel) {
      subscribe({
        "provider": channel.provider,
        "channelId": channel.channelId,
      });
    });

    _messages.clear();
    notifyListeners();

    _subscription?.cancel();
    if (channels.isEmpty) {
      _subscription = null;
    } else {
      final channelIds = channels
          .map((channel) => "${channel.provider}:${channel.channelId}")
          .toList();
      _subscription = FirebaseFirestore.instance
          .collection("messages")
          .where("channelId", whereIn: channelIds)
          .orderBy("timestamp")
          .limitToLast(250)
          .snapshots()
          .listen((event) {
        event.docChanges.forEach((change) {
          // only process appends.
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) {
              return;
            }

            switch (data['type']) {
              case "message":
                final message = data['message'];
                final tags = data['tags'];
                String author = tags['display-name'] ?? tags['username'];
                if (author.toLowerCase() != tags['username']) {
                  // this is an internationalized name.
                  author = "${tags['display-name']} (${tags['username']})";
                }

                _messages.add(TwitchMessageModel(
                  messageId: tags['id'],
                  channel: data['channel'],
                  author: author,
                  message: message,
                  tags: tags,
                  timestamp: data['timestamp'].toDate(),
                  deleted: false,
                ));

                switch (tags['message-type']) {
                  case "action":
                    _ttsModule.speak("$author $message");
                    break;
                  case "chat":
                    _ttsModule.speak("$author said: $message");
                    break;
                }
                break;
              case "messagedeleted":
                final messageId = data['messageId'];
                final index = _messages.indexWhere((element) {
                  if (element is TwitchMessageModel) {
                    return element.messageId == messageId;
                  }
                  return false;
                });
                if (index > -1) {
                  final message = _messages[index];
                  if (message is TwitchMessageModel) {
                    _messages[index] = TwitchMessageModel(
                      messageId: message.messageId,
                      channel: message.channel,
                      author: message.author,
                      message: message.message,
                      tags: message.tags,
                      timestamp: message.timestamp,
                      deleted: true,
                    );
                  }
                }
                break;
              case "raided":
                _messages.add(TwitchRaidEventModel(
                  profilePictureUrl: data['tags']['msg-param-profileImageURL'],
                  fromUsername: data['username'],
                  viewers: data['viewers'],
                ));
                break;
            }
          }
        });

        notifyListeners();
      }, onDone: () {
        FirebaseCrashlytics.instance
            .log("unexpected done handler called on firestore listener");
      }, onError: (error) {
        FirebaseCrashlytics.instance.recordError(error, StackTrace.current,
            reason: "messages listener error");
      });
    }
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<MessageModel> get messages => _messages;

  bool get ttsEnabled => _ttsModule.enabled;

  set ttsEnabled(bool enabled) {
    _ttsModule.enabled = enabled;
    notifyListeners();
  }

  bool get ttsIsBotMuted => _ttsModule.isBotMuted;

  set ttsIsBotMuted(bool value) {
    _ttsModule.isBotMuted = value;
    notifyListeners();
  }

  double get ttsSpeed => _ttsModule.speed;

  set ttsSpeed(double value) {
    _ttsModule.speed = value;
    notifyListeners();
  }

  double get ttsPitch => _ttsModule.pitch;

  set ttsPitch(double value) {
    _ttsModule.pitch = value;
    notifyListeners();
  }
}
