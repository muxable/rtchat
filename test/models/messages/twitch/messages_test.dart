import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages.dart';

void main() {
  test("TwitchMessageConfig json roundtrip empty json", () {
    final model = MessagesModel.fromJson({});
    final want = model.toJson();
    final got = MessagesModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  test("TwitchMessageConfig json roundtrip with sample", () {
    final json = {
      'modMessageDuration': 6,
      'vipMessageDuration': 6,
    };
    final model = MessagesModel.fromJson(json);
    final want = model.toJson();
    final got = MessagesModel.fromJson(model.toJson()).toJson();
    expect(got, equals(want));
  });
}
