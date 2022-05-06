import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/twitch/eventsub_configuration.dart';

void main() {
  test("EventSubConfigurationModel json roundtrip empty json", () {
    final model = EventSubConfigurationModel.fromJson({});
    final want = model.toJson();
    final got = EventSubConfigurationModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  test("EventSubConfigurationModel json roundtrip", () {
    final json = {
      'followEventConfig': {'showEvent': true, 'eventDuration': 28},
      'subscriptionEventConfig': {
        'showEvent': true,
        'showIndividualGifts': true,
        'eventDuration': 30
      },
      'cheerEventConfig': {'showEvent': false, 'eventDuration': 30},
      'raidEventConfig': {
        'showEvent': true,
        'eventDuration': 6,
        'enableShoutoutButton': true
      },
      'pollEventConfig': {'showEvent': true, 'eventDuration': 6},
      'channelPointRedemptionEventConfig': {
        'showEvent': true,
        'eventDuration': 6,
        'unfulfilledAdditionalDuration': 0
      },
      'hypetrainEventConfig': {'showEvent': true, 'eventDuration': 6},
      'predictionEventConfig': {'showEvent': true, 'eventDuration': 6}
    };
    final model = EventSubConfigurationModel.fromJson(json);
    final want = model.toJson();
    final got = EventSubConfigurationModel.fromJson(model.toJson()).toJson();
    expect(got, equals(want));
  });
}
