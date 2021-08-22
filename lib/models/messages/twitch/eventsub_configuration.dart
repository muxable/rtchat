import 'package:flutter/material.dart';

class FollowEventConfig {
  bool showEvent;
  bool isEventPinnable;
  double eventDuration;

  FollowEventConfig(this.showEvent, this.isEventPinnable, this.eventDuration);

  FollowEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        isEventPinnable = json['isEventPinnable'],
        eventDuration = json['eventDuration'];

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "isEventPinnable": isEventPinnable,
        "eventDuration": eventDuration,
      };
}

class SubscriptionEventConfig {
  bool showEvent;
  bool isEventPinnable;
  double eventDuration;

  SubscriptionEventConfig(
      this.showEvent, this.isEventPinnable, this.eventDuration);

  SubscriptionEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        isEventPinnable = json['isEventPinnable'],
        eventDuration = json['eventDuration'];

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "isEventPinnable": isEventPinnable,
        "eventDuration": eventDuration,
      };
}

class CheerEventConfig {
  bool showEvent;
  bool isEventPinnable;
  double eventDuration;

  CheerEventConfig(this.showEvent, this.isEventPinnable, this.eventDuration);

  CheerEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        isEventPinnable = json['isEventPinnable'],
        eventDuration = json['eventDuration'];

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "isEventPinnable": isEventPinnable,
        "eventDuration": eventDuration,
      };
}

class EventSubConfigurationModel extends ChangeNotifier {
  FollowEventConfig followEventConfig = FollowEventConfig(false, false, 5.0);
  SubscriptionEventConfig subscriptionEventConfig =
      SubscriptionEventConfig(false, false, 5);
  CheerEventConfig cheerEventConfig = CheerEventConfig(true, true, 5);
  // other configs
  // final HypeTrainEventConfig;

  setFollowEventDuration(double value) {
    followEventConfig.eventDuration = value;
    notifyListeners();
  }

  setFollowEventShowable(bool value) {
    followEventConfig.showEvent = value;
    notifyListeners();
  }

  setFollowEventPinnable(bool value) {
    followEventConfig.isEventPinnable = value;
    notifyListeners();
  }

  EventSubConfigurationModel.fromJson(Map<String, dynamic> json) {
    if (json['followEventConfig'] != null) {
      followEventConfig = FollowEventConfig.fromJson(json['followEventConfig']);
    }
    if (json['subscriptionEventConfig'] != null) {
      subscriptionEventConfig =
          SubscriptionEventConfig.fromJson(json['subscriptionEventConfig']);
    }
    if (json['cheerEventConfig'] != null) {
      cheerEventConfig = CheerEventConfig.fromJson(json['cheerEventConfig']);
    }
  }

  Map<String, dynamic> toJson() => {
        "followEventConfig": followEventConfig,
        'subscriptionEventConfig': subscriptionEventConfig,
        'cheerEventConfig': cheerEventConfig
      };
}
