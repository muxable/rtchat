import 'dart:async';
import 'dart:core';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rtchat/foreground_service_channel.dart';
import 'package:rtchat/models/channels.dart';

class AudioSource {
  final String? name;
  final Uri url;
  final bool muted;

  AudioSource(this.name, this.url, this.muted);

  AudioSource withMuted(bool muted) => AudioSource(name, url, muted);

  @override
  bool operator ==(other) => other is AudioSource && other.url == url;

  @override
  int get hashCode => url.hashCode;

  AudioSource.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        url = Uri.parse(json['url']),
        muted = json['muted'];

  Map<String, dynamic> toJson() => {
        "name": name,
        "url": url.toString(),
        "muted": muted,
      };

  @override
  String toString() => url.toString();
}

class AudioModel extends ChangeNotifier {
  final List<AudioSource> _sources = [];
  final Map<AudioSource, HeadlessInAppWebView> _views = {};
  late final Timer _speakerDisconnectTimer;
  final _audioCache = AudioCache();
  final initialOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          mediaPlaybackRequiresUserGesture: false, javaScriptEnabled: true));
  var _isForegroundServiceEnabled = false;

  Channel? _hostChannel;
  StreamSubscription? _hostChannelStateSubscription;

  @override
  void dispose() {
    _hostChannelStateSubscription?.cancel();
    _speakerDisconnectTimer.cancel();

    super.dispose();
  }

  bool get isForegroundServiceEnabled => _isForegroundServiceEnabled;

  set isForegroundServiceEnabled(bool isEnabled) {
    _isForegroundServiceEnabled = isEnabled;
    _bindHostChannelStateSubscription();
    notifyListeners();
  }

  Channel? get hostChannel => _hostChannel;

  set hostChannel(Channel? channel) {
    _hostChannel = channel;
    _bindHostChannelStateSubscription();
  }

  void _bindHostChannelStateSubscription() {
    _hostChannelStateSubscription?.cancel();
    if (_hostChannel == null || !_isForegroundServiceEnabled) {
      _hostChannelStateSubscription = null;
      ForegroundServiceChannel.stop();
      return;
    }
    _hostChannelStateSubscription = FirebaseFirestore.instance
        .collection("messages")
        .where("channelId", isEqualTo: _hostChannel.toString())
        .where("type", whereIn: ["stream.online", "stream.offline"])
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots()
        .listen((event) {
          if (event.docs.isNotEmpty &&
              event.docs.first.get("type") == "stream.online") {
            ForegroundServiceChannel.start();
          } else {
            ForegroundServiceChannel.stop();
          }
        });
  }

  List<AudioSource> get sources => _sources;

  int get unmutedSourceCount =>
      _sources.where((element) => !element.muted).length;

  Future<void> addSource(AudioSource source) async {
    if (_sources.contains(source)) {
      return;
    }
    _sources.add(source);
    await _syncWebView(source);
    notifyListeners();
  }

  Future<void> removeSource(AudioSource source) async {
    _sources.remove(source);
    await _syncWebView(source);
    notifyListeners();
  }

  Future<void> toggleSource(AudioSource source) async {
    final index = _sources.indexOf(source);
    if (index != -1) {
      _sources[index] = source.withMuted(!source.muted);
      await _syncWebView(_sources[index]);
    }
    notifyListeners();
  }

  Future<void> refreshAllSources() async {
    for (final source in _sources) {
      await _syncWebView(source);
    }
  }

  Future<void> _syncWebView(AudioSource source) async {
    _views[source]?.dispose();
    if (source.muted) {
      _views.remove(source);
    } else {
      final view = HeadlessInAppWebView(
          initialOptions: initialOptions,
          initialUrlRequest: URLRequest(url: source.url));
      _views[source] = view;
      await view.run();
    }
  }

  AudioModel.fromJson(Map<String, dynamic> json) {
    _speakerDisconnectTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _audioCache.play("silence.mp3"),
    );
    final sources = json['sources'];
    if (sources != null) {
      for (dynamic source in sources) {
        addSource(AudioSource.fromJson(source));
      }
    }
    if (json['isForegroundServiceEnabled'] ?? false) {
      _isForegroundServiceEnabled = json['isForegroundServiceEnabled'];
      ForegroundServiceChannel.start();
    }
  }

  Map<String, dynamic> toJson() => {
        "sources": _sources.map((source) => source.toJson()).toList(),
        "isForegroundServiceEnabled": _isForegroundServiceEnabled,
      };
}
