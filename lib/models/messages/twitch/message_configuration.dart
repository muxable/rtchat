import 'package:flutter/material.dart';

class TwitchMessageConfig extends ChangeNotifier {
  Duration announcementPinDuration = const Duration(seconds: 10);

  setAnnouncementPinDuration(Duration duration) {
    announcementPinDuration = duration;
    notifyListeners();
  }

  TwitchMessageConfig.fromJson(Map<String, dynamic> json) {
    if (json['announcementPinDuration'] != null) {
      announcementPinDuration =
          Duration(seconds: json['announcementPinDuration'].toInt());
    }
  }

  Map<String, dynamic> toJson() => {
        "announcementPinDuration": announcementPinDuration.inSeconds.toInt(),
      };
}
