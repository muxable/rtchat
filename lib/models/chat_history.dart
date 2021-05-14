import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TwitchMessage {
  final String channel;
  final String author;
  final String message;
  final Map<String, dynamic> tags;
  final DateTime timestamp;

  TwitchMessage(
      this.channel, this.author, this.message, this.tags, this.timestamp);
}

class ChatHistoryModel extends ChangeNotifier {
  final Set<String> _subscribedKeys = {};

  StreamSubscription<QuerySnapshot>? _subscription;

  final List<TwitchMessage> _messages = [];

  final FlutterTts _flutterTts = FlutterTts();

  bool _ttsEnabled = false;

  Future<void> subscribe(String provider, String channel) async {
    final key = "$provider:$channel";
    if (_subscribedKeys.contains(key)) {
      return;
    }
    final subscribe = FirebaseFunctions.instance.httpsCallable('subscribe');
    await subscribe({
      "provider": provider,
      "channel": channel,
    });
    _subscribedKeys.add(key);

    _rebindStream();

    notifyListeners();
  }

  void unsubscribe(String provider, String channel) {
    final key = "$provider:$channel";
    if (!_subscribedKeys.contains(key)) {
      return;
    }
    _subscribedKeys.remove(key);

    _rebindStream();

    notifyListeners();
  }

  void _rebindStream() {
    _messages.clear();
    notifyListeners();

    _subscription?.cancel();
    if (_subscribedKeys.isEmpty) {
      _subscription = null;
    } else {
      _subscription = FirebaseFirestore.instance
          .collection("messages")
          .where("channel", whereIn: _subscribedKeys.toList())
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

            _messages.add(TwitchMessage(data['channel'], author, message, tags,
                data['timestamp'].toDate()));

            if (ttsEnabled) {
              _flutterTts.speak("$author said $message");
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

  List<TwitchMessage> get messages {
    return _messages;
  }

  bool get ttsEnabled {
    return _ttsEnabled;
  }

  set ttsEnabled(bool enabled) {
    _ttsEnabled = enabled;
    notifyListeners();
  }
}
