import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/speaker_keep_alive.dart';

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
  final SpeakerKeepAlive _speakerKeepAlive;

  bool _isOnline = false;
  bool _isSettingsVisible = false;
  bool _isAlwaysEnabled = false;

  Channel? _hostChannel;
  StreamSubscription? _hostChannelStateSubscription;

  // Android may refuse to start the audio service from the background, so a
  // failed sync is retried when the app resumes.
  late final AppLifecycleListener _lifecycleListener;
  bool _syncFailed = false;
  int _syncId = 0;

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _hostChannelStateSubscription?.cancel();
    _speakerKeepAlive.dispose();

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

  // sources only play on the home screen for a signed in streamer, but can
  // always be previewed from the settings screen.
  bool get enabled =>
      _isSettingsVisible ||
      (_hostChannel != null && (_isOnline || _isAlwaysEnabled));

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
    if (!enabled) {
      return 0;
    }
    final count = _sources.where((element) => !element.muted).length;
    if (count > 0) {
      await AudioChannel.reload();
    }
    return count;
  }

  Future<void> _syncWebViews() async {
    final id = ++_syncId;
    final ok = await AudioChannel.set(
      enabled
          ? _sources
              .where((element) => !element.muted)
              .map((element) => element.url.toString())
              .toList()
          : [],
    );
    // only the latest sync reflects the requested state.
    if (id == _syncId) {
      _syncFailed = !ok;
    }
  }

  Future<void> showAudioPermissionDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)!.audioSourcesRequirePermissions,
          ),
          content: Text(
            AppLocalizations.of(context)!.audioSourcesRequirePermissionsMessage,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.audioSourcesRemoveButton,
              ),
              onPressed: () {
                _sources.clear();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                AppLocalizations.of(context)!.audioSourcesOpenSettingsButton,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await AudioChannel.requestPermission();
              },
            ),
          ],
        );
      },
    );
  }

  AudioModel.fromJson(Map<String, dynamic> json)
    : _speakerKeepAlive = SpeakerKeepAlive() {
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (_syncFailed) {
          _syncWebViews();
        }
      },
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
