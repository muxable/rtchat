import 'package:flutter/material.dart';

class FollowEventConfig {
  final bool showEvent;
  final bool isEventPinnable;
  final int eventDuration;

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
  final bool showEvent;
  final bool isEventPinnable;
  final int eventDuration;

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
  final bool showEvent;
  final bool isEventPinnable;
  final int eventDuration;

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
  FollowEventConfig followEventConfig = FollowEventConfig(false, false, 5);
  SubscriptionEventConfig subscriptionEventConfig =
      SubscriptionEventConfig(false, false, 5);
  CheerEventConfig cheerEventConfig = CheerEventConfig(true, true, 5);
  // other event configs
  // final HypeTrainEventConfig;

  EventSubConfigurationModel.fromJson(Map<String, dynamic> json) {
    followEventConfig = FollowEventConfig.fromJson(json['followEventConfig']);
    subscriptionEventConfig =
        SubscriptionEventConfig.fromJson(json['subscriptionEventConfig']);
    cheerEventConfig = CheerEventConfig.fromJson(json['cheerEventConfig']);
  }

  Map<String, dynamic> toJson() => {
        "followEventConfig": followEventConfig,
        'subscriptionEventConfig': subscriptionEventConfig,
        'cheerEventConfig': cheerEventConfig
      };
}
