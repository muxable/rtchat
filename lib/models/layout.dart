import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class Channel {
  String provider;
  String channelId;
  String displayName;

  Channel(this.provider, this.channelId, this.displayName);

  bool operator ==(that) =>
      that is Channel &&
      that.provider == this.provider &&
      that.channelId == this.channelId;

  int get hashCode => provider.hashCode ^ channelId.hashCode;

  @override
  String toString() => "$provider:$channelId";
}

class LayoutModel extends ChangeNotifier {
  Set<String> _audioSources = {};
  double _fontSize = 20;
  double _panelHeight = 100.0;
  double _panelWidth = 100.0;
  double _lightnessBoost = 0.179;
  bool _isStatsVisible = true;
  bool _isInputLockable = false;
  bool _locked = false;
  Timer? _speakerDisconnectTimer;
  final AudioCache _audioCache = AudioCache();
  Set<Channel> _channels = {};

  void updatePanelHeight({required double dy}) {
    _panelHeight += dy;
    _panelHeight = max(_panelHeight, 1);
    _panelHeight = min(_panelHeight, 400);
    notifyListeners();
  }

  void updatePanelWidth({required double dx}) {
    _panelWidth += dx;
    _panelWidth = max(_panelWidth, 1);
    _panelWidth = min(_panelWidth, 400);
    notifyListeners();
  }

  double get fontSize {
    return _fontSize;
  }

  set fontSize(double fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }

  double get panelHeight {
    return _panelHeight;
  }

  double get panelWidth {
    return _panelWidth;
  }

  double get lightnessBoost {
    return _lightnessBoost;
  }

  set lightnessBoost(double lightnessBoost) {
    _lightnessBoost = lightnessBoost;
    notifyListeners();
  }

  bool get locked {
    return _locked;
  }

  set locked(bool locked) {
    _locked = locked;
    notifyListeners();
  }

  bool get isStatsVisible {
    return _isStatsVisible;
  }

  set isStatsVisible(bool isStatsVisible) {
    _isStatsVisible = isStatsVisible;
    notifyListeners();
  }

  bool get isInputLockable {
    return _isInputLockable;
  }

  set isInputLockable(bool isInputLockable) {
    _isInputLockable = isInputLockable;
    notifyListeners();
  }

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

  void _startSpeakerDisconnectTimer() {
    _speakerDisconnectTimer = Timer.periodic(
      Duration(minutes: 5),
      (_) => _audioCache.play("silence.mp3"),
    );
  }

  Set<Channel> get channels {
    return _channels;
  }

  set channels(Set<Channel> channels) {
    _channels = channels;
    notifyListeners();
  }

  LayoutModel.fromJson(Map<String, dynamic> json) {
    // final tabs = json['tabs'];
    // if (tabs != null) {
    //   for (dynamic tab in tabs) {
    //     addTab(PanelTab.fromJson(tab));
    //   }
    // }
    if (json['panelHeight'] != null) {
      _panelHeight = json['panelHeight'];
    }
    if (json['panelWidth'] != null) {
      _panelWidth = json['panelWidth'];
    }
    if (json['lightnessBoost'] != null) {
      _lightnessBoost = json['lightnessBoost'];
    }
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
    }
    if (json['locked'] != null) {
      _locked = json['locked'];
    }
    if (json['isStatsVisible'] != null) {
      _isStatsVisible = json['isStatsVisible'];
    }
    if (json['isInputLockable'] != null) {
      _isInputLockable = json['isInputLockable'];
    }
    if (json['isSpeakerDisconnectPreventionEnabled'] ?? false) {
      _startSpeakerDisconnectTimer();
    }
  }

  Map<String, dynamic> toJson() => {
        // "tabs": _tabs.map((tab) => tab.toJson()).toList(),
        "panelHeight": _panelHeight,
        "panelWidth": _panelWidth,
        "lightnessBoost": _lightnessBoost,
        "fontSize": _fontSize,
        "locked": _locked,
        "isStatsVisible": _isStatsVisible,
        "isInputLockable": _isInputLockable,
        "isSpeakerDisconnectPreventionEnabled": _speakerDisconnectTimer != null,
      };
}
