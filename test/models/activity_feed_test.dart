import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/activity_feed.dart';

void main() {
  test("ActivityFeedModel json roundtrip", () {
    final model = ActivityFeedModel.fromJson({});
    final want = model.toJson();
    final got = ActivityFeedModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });
}
