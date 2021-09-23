import 'package:flutter/material.dart';

class TwitchMessageConfig extends ChangeNotifier {
  Duration modMessageDuration = const Duration(seconds: 6);
  Duration vipMessageDuration = const Duration(seconds: 6);

  setModMessageDuration(Duration duration) {
    modMessageDuration = duration;
    notifyListeners();
  }

  setVipMessageDuration(Duration duration) {
    vipMessageDuration = duration;
    notifyListeners();
  }

  TwitchMessageConfig.fromJson(Map<String, dynamic> json) {
    if (json['modMessageDuration'] != null) {
      modMessageDuration =
          Duration(seconds: json['modMessageDuration'].toInt());
    }
    if (json['vipMessageDuration'] != null) {
      vipMessageDuration =
          Duration(seconds: json['vipMessageDuration'].toInt());
    }
  }

  Map<String, dynamic> toJson() => {
        "modMessageDuration": modMessageDuration.inSeconds.toInt(),
        "vipMessageDuration": vipMessageDuration.inSeconds.toInt(),
      };
}
