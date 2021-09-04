import 'package:flutter/material.dart';

class FollowEventConfig {
  bool showEvent;
  Duration eventDuration;

  FollowEventConfig(this.showEvent, this.eventDuration);

  FollowEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class SubscriptionEventConfig {
  bool showEvent;
  bool showIndividualGifts;
  Duration eventDuration;

  SubscriptionEventConfig(
      this.showEvent, this.showIndividualGifts, this.eventDuration);

  SubscriptionEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        showIndividualGifts = json['showIndividualGifts'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "showIndividualGifts": showIndividualGifts,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class CheerEventConfig {
  bool showEvent;
  Duration eventDuration;

  CheerEventConfig(this.showEvent, this.eventDuration);

  CheerEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class RaidEventConfig {
  bool showEvent;
  Duration eventDuration;

  RaidEventConfig(this.showEvent, this.eventDuration);

  RaidEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class PollEventConfig {
  bool showEvent;
  Duration eventDuration;

  PollEventConfig(this.showEvent, this.eventDuration);

  PollEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class HypetrainEventConfig {
  bool showEvent;
  Duration eventDuration;

  HypetrainEventConfig(this.showEvent, this.eventDuration);

  HypetrainEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class EventSubConfigurationModel extends ChangeNotifier {
  FollowEventConfig followEventConfig =
      FollowEventConfig(false, const Duration(seconds: 2));
  SubscriptionEventConfig subscriptionEventConfig =
      SubscriptionEventConfig(false, false, const Duration(seconds: 6));
  CheerEventConfig cheerEventConfig =
      CheerEventConfig(true, const Duration(seconds: 6));
  RaidEventConfig raidEventConfig =
      RaidEventConfig(true, const Duration(seconds: 6));
  PollEventConfig pollEventConfig =
      PollEventConfig(true, const Duration(seconds: 6));
  HypetrainEventConfig hypetrainEventConfig =
      HypetrainEventConfig(true, const Duration(seconds: 6));
  // other configs
  // final HypeTrainEventConfig;

  setFollowEventDuration(Duration duration) {
    followEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setFollowEventShowable(bool value) {
    followEventConfig.showEvent = value;
    notifyListeners();
  }

  setCheerEventDuration(Duration duration) {
    cheerEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setCheerEventShowable(bool value) {
    cheerEventConfig.showEvent = value;
    notifyListeners();
  }

  setSubscriptionEventDuration(Duration duration) {
    subscriptionEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setSubscriptionEventShowable(bool value) {
    subscriptionEventConfig.showEvent = value;
    notifyListeners();
  }

  setGiftSubscriptionStatus(bool value) {
    subscriptionEventConfig.showIndividualGifts = value;
    notifyListeners();
  }

  setRaidEventDuration(Duration duration) {
    raidEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setRaidEventShowable(bool value) {
    raidEventConfig.showEvent = value;
    notifyListeners();
  }

  setPollEventDuration(Duration duration) {
    pollEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setPollEventShowable(bool value) {
    pollEventConfig.showEvent = value;
    notifyListeners();
  }

  setHypetrainEventDuration(Duration duration) {
    hypetrainEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setHypetrainEventShowable(bool value) {
    hypetrainEventConfig.showEvent = value;
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
    if (json['raidEventConfig'] != null) {
      raidEventConfig = RaidEventConfig.fromJson(json['raidEventConfig']);
    }
    if (json['pollEventConfig'] != null) {
      pollEventConfig = PollEventConfig.fromJson(json['pollEventConfig']);
    }
    if (json['hypetrainEventConfig'] != null) {
      hypetrainEventConfig =
          HypetrainEventConfig.fromJson(json['hypetrainEventConfig']);
    }
  }

  Map<String, dynamic> toJson() => {
        "followEventConfig": followEventConfig,
        "subscriptionEventConfig": subscriptionEventConfig,
        "cheerEventConfig": cheerEventConfig,
        "raidEventConfig": raidEventConfig,
        "pollEventConfig": pollEventConfig,
        "hypeTrainConfig": hypetrainEventConfig,
      };
}
