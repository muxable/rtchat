import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:rtchat/models/style.dart';

void main() {
  test("StyleModel json roundtrip", () {
    final model = StyleModel.fromJson({});
    final want = model.toJson();
    final got = StyleModel.fromJson(model.toJson()).toJson();

    expect(got, equals(want));
  });

  group("getDisplayName", () {
    final model = StyleModel.fromJson({});

    KickUserModel kick(String username, String slug) => KickUserModel.fromJson(
        {'user_id': 1, 'username': username, 'channel_slug': slug});

    test("hides a kick slug that only swaps underscores for dashes", () {
      expect(model.getDisplayName(kick("For_Example", "for-example")),
          "For_Example");
    });

    test("shows the login when it differs from the display name", () {
      expect(model.getDisplayName(kick("Someone", "someone-else")),
          "Someone (someone-else)");
    });
  });
}
