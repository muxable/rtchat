import 'dart:async';
import 'dart:core';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rtchat/foreground_service_channel.dart';

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
  Timer? _speakerDisconnectTimer;
  final _audioCache = AudioCache();
  final initialOptions = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          mediaPlaybackRequiresUserGesture: false, javaScriptEnabled: true));
  var _isForegroundServiceEnabled = false;

  bool get isSpeakerDisconnectPreventionEnabled {
    return _speakerDisconnectTimer != null;
  }

  set isSpeakerDisconnectPreventionEnabled(bool isEnabled) {
    if (isEnabled) {
      _startSpeakerDisconnectTimer();
    } else {
      _speakerDisconnectTimer?.cancel();
      _speakerDisconnectTimer = null;
    }
    notifyListeners();
  }

  bool get isForegroundServiceEnabled => _isForegroundServiceEnabled;

  set isForegroundServiceEnabled(bool isEnabled) {
    if (isEnabled) {
      ForegroundServiceChannel.start();
    } else {
      ForegroundServiceChannel.stop();
    }
    _isForegroundServiceEnabled = isEnabled;
    notifyListeners();
  }

  void _startSpeakerDisconnectTimer() {
    _speakerDisconnectTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _audioCache.play("silence.mp3"),
    );
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
    final sources = json['sources'];
    if (sources != null) {
      for (dynamic source in sources) {
        addSource(AudioSource.fromJson(source));
      }
    }
    if (json['isSpeakerDisconnectPreventionEnabled'] ?? false) {
      _startSpeakerDisconnectTimer();
    }
    if (json['isForegroundServiceEnabled'] ?? false) {
      _isForegroundServiceEnabled = json['isForegroundServiceEnabled'];
      ForegroundServiceChannel.start();
    }
  }

  Map<String, dynamic> toJson() => {
        "sources": _sources.map((source) => source.toJson()).toList(),
        "isSpeakerDisconnectPreventionEnabled": _speakerDisconnectTimer != null,
        "isForegroundServiceEnabled": _isForegroundServiceEnabled,
      };
}
