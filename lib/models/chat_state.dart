import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rtchat/models/channels.dart';

class Viewers {
  final List<String> broadcaster;
  final List<String> moderators;
  final List<String> vips;
  final List<String> viewers;

  Viewers({
    required this.broadcaster,
    required this.moderators,
    required this.vips,
    required this.viewers,
  });

  // create a new instance that filters to viewers matching a certain substring.
  Viewers query(String text) {
    if (text.isEmpty) {
      return this;
    }
    return Viewers(
      broadcaster: broadcaster.where((name) => name.contains(text)).toList(),
      moderators: moderators.where((name) => name.contains(text)).toList(),
      vips: vips.where((name) => name.contains(text)).toList(),
      viewers: viewers.where((name) => name.contains(text)).toList(),
    );
  }
}

class ChatStateModel extends ChangeNotifier {
  StreamSubscription<void>? _subscription;
  Viewers? _viewers;
  Channel? _channel;

  set channel(Channel? channel) {
    // ignore if no update
    if (channel == _channel) {
      return;
    }
    _channel = channel;
    _viewers = null;
    notifyListeners();

    _subscription?.cancel();
    if (channel != null) {
      _subscription = FirebaseFirestore.instance
          .collection('chat-status')
          .where("channelId", isEqualTo: channel.toString())
          .orderBy("createdAt", descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) {
          return;
        }
        final doc = snapshot.docs.first.data();
        _viewers = Viewers(
          broadcaster: doc['broadcaster'] as List<String>,
          moderators: doc['moderators'] as List<String>,
          vips: doc['vips'] as List<String>,
          viewers: doc['viewers'] as List<String>,
        );
        notifyListeners();
      });
    }
  }

  // can be null if still loading.
  Viewers? get viewers => _viewers;
}
