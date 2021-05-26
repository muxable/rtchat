import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/message.dart';

class ChatHistoryModel extends ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _messagesSub;
  StreamSubscription<QuerySnapshot>? _deletionsSub;

  final List<MessageModel> _messages = [];
  final Set<String> _deletedMessageIds = {};

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

    _messagesSub?.cancel();
    _deletionsSub?.cancel();
    if (channels.isEmpty) {
      _messagesSub = null;
      _deletionsSub = null;
    } else {
      final channelIds = channels
          .map((channel) => "${channel.provider}:${channel.channelId}")
          .toList();
      _messagesSub = FirebaseFirestore.instance
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
              deleted: _deletedMessageIds.contains("twitch:${tags['id']}"),
            ));

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
      _deletionsSub = FirebaseFirestore.instance
          .collection("deletions")
          .where("channelId", whereIn: channelIds)
          .orderBy("timestamp")
          .limitToLast(250)
          .snapshots()
          .listen((event) {
        event.docChanges.forEach((change) {
          // only process appends.
          if (change.type == DocumentChangeType.added) {
            _deletedMessageIds.add(change.doc.id);
            final tokens = change.doc.id.split(":");
            final provider = tokens[0];
            final messageId = tokens[1];
            for (var i = 0; i < _messages.length; i++) {
              final message = _messages[i];
              if (provider == "twitch" &&
                  message is TwitchMessageModel &&
                  message.messageId == messageId) {
                _messages[i] = TwitchMessageModel(
                    author: message.author,
                    channel: message.channel,
                    messageId: message.messageId,
                    message: message.message,
                    tags: message.tags,
                    timestamp: message.timestamp,
                    deleted: true);
              }
            }
          }
        });

        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _deletionsSub?.cancel();
    super.dispose();
  }

  List<MessageModel> get messages {
    return _messages;
  }

  Set<String> get deletedMessageIds {
    return _deletedMessageIds;
  }

  bool get ttsEnabled {
    return _ttsModule.enabled;
  }

  set ttsEnabled(bool enabled) {
    _ttsModule.enabled = enabled;
    notifyListeners();
  }
}
