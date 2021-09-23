import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/twitch/message_configuration.dart';

void main() {
  test("TwitchMessageConfig json roundtrip empty json", () {
    final model = TwitchMessageConfig.fromJson({});
    final want = model.toJson();
    final got = TwitchMessageConfig.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  test("TwitchMessageConfig json roundtrip with sample", () {
    final json = {
      'modMessageDuration': 6,
      'vipMessageDuration': 6,
    };
    final model = TwitchMessageConfig.fromJson(json);
    final want = model.toJson();
    final got = TwitchMessageConfig.fromJson(model.toJson()).toJson();
    expect(got, equals(want));
  });
}
