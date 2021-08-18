import 'package:flutter/material.dart';

class EventSubConfigurationModel extends ChangeNotifier {
  bool showFollowEvent = true;
  bool showCheerEvent = true;
  bool showSubEvent = true;
  bool showGiftedSubEvent = true;
  bool showChannelPointEvent = true;
  bool showHypeTrainEvent = true;
  bool showPredictionEvent = true;
  bool showPollEvent = true;

  bool isFollowEventPinnable = false;
  bool isCheerEventPinnable = false;
  bool isSubEventPinnable = false;
  bool isGiftedSubEventPinnable = false;
  bool isChannelPointEventPinnable = false;
  bool isHypeTrainEventPinnable = false;
  bool isPredictionEventPinnable = false;
  bool isPollEventPinnable = false;

  double followEventPinDuration = 5;
  double cheerEventPinDuration = 5;
  double subEventPinDuration = 5;
  double giftedSubEventPinDuration = 5;
  double channelPointEventPinDuration = 5;

  EventSubConfigurationModel.fromJson(Map<String, dynamic> json) {
    if (json['showFollowEvent'] != null) {
      showFollowEvent = json['showFollowEvent'];
    }
    if (json['showCheerEvent'] != null) {
      showCheerEvent = json['showCheerEvent'];
    }
    if (json['showSubEvent'] != null) {
      showSubEvent = json['showSubEvent'];
    }
    if (json['showGiftedSubEvent'] != null) {
      showGiftedSubEvent = json['showGiftedSubEvent'];
    }
    if (json['showChannelPointEvent'] != null) {
      showChannelPointEvent = json['showChannelPointEvent'];
    }
    if (json['showHypeTrainEvent'] != null) {
      showHypeTrainEvent = json['showHypeTrainEvent'];
    }
    if (json['showPredictionEvent'] != null) {
      showPredictionEvent = json['showPredictionEvent'];
    }
    if (json['showPollEvent'] != null) {
      showPollEvent = json['showPollEvent'];
    }
    if (json['isFollowEventPinnable'] != null) {
      isFollowEventPinnable = json['isFollowEventPinnable'];
    }
    if (json['isCheerEventPinnable'] != null) {
      isCheerEventPinnable = json['isCheerEventPinnable'];
    }
    if (json['isGiftedSubEventPinnable'] != null) {
      isGiftedSubEventPinnable = json['isGiftedSubEventPinnable'];
    }
    if (json['isChannelPointEventPinnable'] != null) {
      isChannelPointEventPinnable = json['isChannelPointEventPinnable'];
    }
    if (json['isPredictionEventPinnable'] != null) {
      isPredictionEventPinnable = json['isPredictionEventPinnable'];
    }
    if (json['isPollEventPinnable'] != null) {
      isPollEventPinnable = json['isPollEventPinnable'];
    }
    if (json['followEventPinDuration'] != null) {
      followEventPinDuration = json['followEventPinDuration'];
    }
    if (json['cheerEventPinDuration'] != null) {
      cheerEventPinDuration = json['cheerEventPinDuration'];
    }
    if (json['subEventPinDuration'] != null) {
      subEventPinDuration = json['subEventPinDuration'];
    }
    if (json['giftedSubEventPinDuration'] != null) {
      giftedSubEventPinDuration = json['giftedSubEventPinDuration'];
    }
    if (json['channelPointEventPinDuration'] != null) {
      channelPointEventPinDuration = json['channelPointEventPinDuration'];
    }
  }

  Map<String, dynamic> toJson() => {
        'showFollowEvent': showFollowEvent,
        'showCheerEvent': showCheerEvent,
        'showSubEvent': showSubEvent,
        'showGiftedSubEvent': showGiftedSubEvent,
        'showChannelPointEvent': showChannelPointEvent,
        'showHypeTrainEvent': showHypeTrainEvent,
        'showPredictionEvent': showPredictionEvent,
        'showPollEvent': showPollEvent,
        'isFollowEventPinnable': isFollowEventPinnable,
        'isCheerEventPinnable': isCheerEventPinnable,
        'isSubEventPinnable': isSubEventPinnable,
        'isGiftedSubEventPinnable': isGiftedSubEventPinnable,
        'isChannelPointEventPinnable': isChannelPointEventPinnable,
        'isHypeTrainEventPinnable': isHypeTrainEventPinnable,
        'isPredictionEventPinnable': isPredictionEventPinnable,
        'isPollEventPinnable': isPollEventPinnable,
        'followEventPinDuration': followEventPinDuration,
        'cheerEventPinDuration': cheerEventPinDuration,
        'subEventPinDuration': subEventPinDuration,
        'giftedSubEventPinDuration': giftedSubEventPinDuration,
        'channelPointEventPinDuration': channelPointEventPinDuration,
      };
}
