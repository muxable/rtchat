import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';

class TwitchMessageModel {
  final String channel;
  final String author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;

  TwitchMessageModel(
      this.channel, this.author, this.message, this.tags, this.timestamp);
}

class ChatHistoryModel extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _subscription;

  final List<TwitchMessageModel> _messages = [];

  final TtsModel _ttsModule;

  ChatHistoryModel(this._ttsModule);

  Future<void> subscribe(Set<Channel> channels) async {
    final subscribe = FirebaseFunctions.instance.httpsCallable('subscribe');
    channels.forEach((channel) {
      subscribe({
        "provider": channel.provider,
        "channel": channel.channel,
      });
    });

    _messages.clear();
    notifyListeners();

    _subscription?.cancel();
    if (channels.isEmpty) {
      _subscription = null;
    } else {
      _subscription = FirebaseFirestore.instance
          .collection("messages")
          .where("channel",
              whereIn: channels
                  .map((channel) => "${channel.provider}:${channel.channel}")
                  .toList())
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

            final message = data['message'];
            final tags = data['tags'];
            final author = tags['display-name'] ?? tags['username'];

            _messages.add(TwitchMessageModel(data['channel'], author, message,
                tags, data['timestamp'].toDate()));

            switch (tags['message-type']) {
              case "action":
                _ttsModule.speak("$author $message");
                break;
              case "chat":
                _ttsModule.speak("$author said: $message");
                break;
            }
          }
        });

        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<TwitchMessageModel> get messages {
    return _messages;
  }

  bool get ttsEnabled {
    return _ttsModule.enabled;
  }

  set ttsEnabled(bool enabled) {
    _ttsModule.enabled = enabled;
    notifyListeners();
  }
}
