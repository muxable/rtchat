import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/user.dart';

void main() {
  test("isBot is case-insensitive", () {
    expect(const TwitchUserModel(userId: "1", login: "Nightbot").isBot, isTrue);
    expect(const TwitchUserModel(userId: "1", login: "STREAMELEMENTS").isBot,
        isTrue);
    expect(const TwitchUserModel(userId: "1", login: "muxfd").isBot, isFalse);
  });

  test("color is deterministic and from the palette", () {
    const a = TwitchUserModel(userId: "1", login: "muxfd");
    const b = TwitchUserModel(userId: "2", login: "muxfd");
    expect(a.color, b.color);
    expect(colors, contains(a.color));
    final n = "muxfd".codeUnits.first + "muxfd".codeUnits.last;
    expect(a.color, colors[n % colors.length]);
  });

  test("asChannel prefers displayName and falls back to login", () {
    expect(
        const TwitchUserModel(userId: "1", login: "foo", displayName: "Foo")
            .asChannel,
        Channel("twitch", "1", "Foo"));
    expect(const TwitchUserModel(userId: "1", login: "foo").asChannel,
        Channel("twitch", "1", "foo"));
  });

  test("equality and toString", () {
    const a = TwitchUserModel(userId: "1", login: "foo", displayName: "Foo");
    expect(a,
        const TwitchUserModel(userId: "1", login: "foo", displayName: "Foo"));
    expect(a, isNot(const TwitchUserModel(userId: "1", login: "foo")));
    expect(a.toString(), "foo");
  });

  test("json round trip", () {
    const a = TwitchUserModel(userId: "1", login: "foo", displayName: "Foo");
    expect(TwitchUserModel.fromJson(a.toJson()), a);
    const b = TwitchUserModel(userId: "2", login: "bar");
    expect(TwitchUserModel.fromJson(b.toJson()), b);
  });
}
