import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/twitch/raiding_event.dart';

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
  bool enableShoutoutButton;

  RaidEventConfig(
      this.showEvent, this.eventDuration, this.enableShoutoutButton);

  RaidEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt()),
        enableShoutoutButton = json['enableShoutoutButton'] ?? false;

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
        "enableShoutoutButton": enableShoutoutButton,
      };
}

class HostEventConfig {
  bool showEvent;
  Duration eventDuration;

  HostEventConfig(this.showEvent, this.eventDuration);

  HostEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class ChannelPointRedemptionEventConfig {
  bool showEvent;
  Duration eventDuration;
  Duration unfulfilledAdditionalDuration;

  ChannelPointRedemptionEventConfig(
      this.showEvent, this.eventDuration, this.unfulfilledAdditionalDuration);

  ChannelPointRedemptionEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt()),
        unfulfilledAdditionalDuration =
            Duration(seconds: json['unfulfilledAdditionalDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
        "unfulfilledAdditionalDuration":
            unfulfilledAdditionalDuration.inSeconds.toInt(),
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

class PredictionEventConfig {
  bool showEvent;
  Duration eventDuration;

  PredictionEventConfig(this.showEvent, this.eventDuration);

  PredictionEventConfig.fromJson(Map<String, dynamic> json)
      : showEvent = json['showEvent'],
        eventDuration = Duration(seconds: json['eventDuration'].toInt());

  Map<String, dynamic> toJson() => {
        "showEvent": showEvent,
        "eventDuration": eventDuration.inSeconds.toInt(),
      };
}

class EventSubConfigurationModel extends ChangeNotifier {
  FollowEventConfig followEventConfig =
      FollowEventConfig(true, const Duration(seconds: 2));
  SubscriptionEventConfig subscriptionEventConfig =
      SubscriptionEventConfig(true, false, const Duration(seconds: 6));
  CheerEventConfig cheerEventConfig =
      CheerEventConfig(true, const Duration(seconds: 6));
  RaidEventConfig raidEventConfig =
      RaidEventConfig(true, const Duration(seconds: 6), false);
  HostEventConfig hostEventConfig =
      HostEventConfig(true, const Duration(seconds: 6));
  ChannelPointRedemptionEventConfig channelPointRedemptionEventConfig =
      ChannelPointRedemptionEventConfig(
          true, const Duration(seconds: 6), const Duration(seconds: 0));
  PollEventConfig pollEventConfig =
      PollEventConfig(true, const Duration(seconds: 6));
  HypetrainEventConfig hypetrainEventConfig =
      HypetrainEventConfig(true, const Duration(seconds: 6));
  PredictionEventConfig predictionEventConfig =
      PredictionEventConfig(true, const Duration(seconds: 6));
  RaidingEventConfig
      raidingEventConfig = // 90 seconds for raid + 10 for join prompt.
      RaidingEventConfig(true, const Duration(seconds: 100));
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

  setRaidEventEnableShoutoutButton(bool value) {
    raidEventConfig.enableShoutoutButton = value;
    notifyListeners();
  }

  setChannelPointRedemptionEventDuration(Duration value) {
    channelPointRedemptionEventConfig.eventDuration = value;
    notifyListeners();
  }

  setChannelPointRedemptionEventShowable(bool value) {
    channelPointRedemptionEventConfig.showEvent = value;
    notifyListeners();
  }

  setChannelPointRedemptionEventUnfulfilledAdditionalDuration(Duration value) {
    channelPointRedemptionEventConfig.unfulfilledAdditionalDuration = value;
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

  setHostEventDuration(Duration duration) {
    hostEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setHostEventShowable(bool value) {
    hostEventConfig.showEvent = value;
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

  setPredictionEventDuration(Duration duration) {
    predictionEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setPredictionEventShowable(bool value) {
    predictionEventConfig.showEvent = value;
    notifyListeners();
  }

  setRaidingEventDuration(Duration duration) {
    raidingEventConfig.eventDuration = duration;
    notifyListeners();
  }

  setRaidingEventShowable(bool value) {
    raidingEventConfig.showEvent = value;
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
    if (json['hostEventConfig'] != null) {
      hostEventConfig = HostEventConfig.fromJson(json['hostEventConfig']);
    }
    if (json['channelPointRedemptionEventConfig'] != null) {
      channelPointRedemptionEventConfig =
          ChannelPointRedemptionEventConfig.fromJson(
              json['channelPointRedemptionEventConfig']);
    }
    if (json['pollEventConfig'] != null) {
      pollEventConfig = PollEventConfig.fromJson(json['pollEventConfig']);
    }
    if (json['hypetrainEventConfig'] != null) {
      hypetrainEventConfig =
          HypetrainEventConfig.fromJson(json['hypetrainEventConfig']);
    }
    if (json['predictionEventConfig'] != null) {
      predictionEventConfig =
          PredictionEventConfig.fromJson(json['predictionEventConfig']);
    }
    if (json['raidingEventConfig'] != null) {
      raidingEventConfig =
          RaidingEventConfig.fromJson(json['raidingEventConfig']);
    }
  }

  Map<String, dynamic> toJson() => {
        "followEventConfig": followEventConfig.toJson(),
        "subscriptionEventConfig": subscriptionEventConfig.toJson(),
        "cheerEventConfig": cheerEventConfig.toJson(),
        "raidEventConfig": raidEventConfig.toJson(),
        "pollEventConfig": pollEventConfig.toJson(),
        "channelPointRedemptionEventConfig":
            channelPointRedemptionEventConfig.toJson(),
        "hostEventConfig": hostEventConfig.toJson(),
        "hypetrainEventConfig": hypetrainEventConfig.toJson(),
        "predictionEventConfig": predictionEventConfig.toJson(),
        "raidingEventConfig": raidingEventConfig.toJson(),
      };
}
