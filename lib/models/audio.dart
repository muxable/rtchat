import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/models/adapters/profiles.dart';
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
  late final Timer _speakerDisconnectTimer;
  final _audioCache = AudioCache(duckAudio: Platform.isIOS);

  bool _isOnline = false;
  bool _isSettingsVisible = false;
  bool _isAlwaysEnabled = false;

  Channel? _hostChannel;
  StreamSubscription? _hostChannelStateSubscription;

  @override
  void dispose() {
    _hostChannelStateSubscription?.cancel();
    _speakerDisconnectTimer.cancel();

    super.dispose();
  }

  Channel? get hostChannel => _hostChannel;

  set hostChannel(Channel? channel) {
    _hostChannel = channel;
    _hostChannelStateSubscription?.cancel();
    if (_hostChannel == null) {
      _hostChannelStateSubscription = null;
      _isOnline = false;
      _syncWebViews();
      notifyListeners();
      return;
    }
    _hostChannelStateSubscription = ProfilesAdapter.instance
        .getIsOnline(channelId: _hostChannel.toString())
        .listen((isOnline) {
      _isOnline = isOnline;
      _syncWebViews();
      notifyListeners();
    });
  }

  bool get isSettingsVisible => _isSettingsVisible;

  set isSettingsVisible(bool value) {
    _isSettingsVisible = value;
    // this is just a signal from the view so don't trigger a notification.
    _syncWebViews();
  }

  bool get isAlwaysEnabled => _isAlwaysEnabled;

  set isAlwaysEnabled(bool value) {
    _isAlwaysEnabled = value;
    notifyListeners();
  }

  List<AudioSource> get sources => _sources;

  bool get enabled => _isOnline || _isSettingsVisible || _isAlwaysEnabled;

  Future<void> addSource(AudioSource source) async {
    if (_sources.contains(source)) {
      return;
    }
    _sources.add(source);
    _syncWebViews();
    notifyListeners();
  }

  Future<void> removeSource(AudioSource source) async {
    _sources.remove(source);
    _syncWebViews();
    notifyListeners();
  }

  Future<void> toggleSource(AudioSource source) async {
    final index = _sources.indexOf(source);
    if (index != -1) {
      _sources[index] = source.withMuted(!source.muted);
      _syncWebViews();
      notifyListeners();
    }
  }

  Future<int> refreshAllSources() async {
    final activeSources = _sources.where((element) => !element.muted).toList();
    for (final source in activeSources) {
      await AudioChannel.reload(source.url.toString());
    }
    return activeSources.length;
  }

  void _syncWebViews() {
    if (enabled) {
      AudioChannel.set(_sources
          .where((element) => !element.muted)
          .map((element) => element.url.toString())
          .toList());
    } else {
      AudioChannel.set([]);
    }
  }

  showAudioPermissionDialog(BuildContext context) {
    return showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (context) {
          return AlertDialog(
            title: Text(
                AppLocalizations.of(context)!.audioSourcesRequirePermissions),
            content: Text(AppLocalizations.of(context)!
                .audioSourcesRequirePermissionsMessage),
            actions: <Widget>[
              TextButton(
                child: Text(
                    AppLocalizations.of(context)!.audioSourcesRemoveButton),
                onPressed: () {
                  _sources.clear();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(AppLocalizations.of(context)!
                    .audioSourcesOpenSettingsButton),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await AudioChannel.requestPermission();
                },
              ),
            ],
          );
        });
  }

  AudioModel.fromJson(Map<String, dynamic> json) {
    _speakerDisconnectTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _audioCache.play("silence.mp3"),
    );
    final sources = json['sources'];
    if (sources != null) {
      for (dynamic source in sources) {
        _sources.add(AudioSource.fromJson(source));
      }
      notifyListeners();
    }
    if (json['isAlwaysEnabled'] != null) {
      _isAlwaysEnabled = json['isAlwaysEnabled'];
    }
  }

  Map<String, dynamic> toJson() => {
        "sources": _sources.map((source) => source.toJson()).toList(),
        "isAlwaysEnabled": _isAlwaysEnabled,
      };
}
