import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';

void main() {
  test("toString is provider:channelId", () {
    expect(Channel("twitch", "123", "Foo").toString(), "twitch:123");
  });

  test("equality ignores language", () {
    final a = Channel("twitch", "123", "Foo", language: "en");
    final b = Channel("twitch", "123", "Foo", language: "fr");
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect({a, b}, hasLength(1));
  });

  test("equality considers provider and channelId only", () {
    final a = Channel(Providers.twitch, "123", "Foo");
    expect(a, isNot(Channel(Providers.kick, "123", "Foo")));
    expect(a, isNot(Channel(Providers.twitch, "456", "Foo")));
    // renaming a channel doesn't make it a different channel.
    expect(a, Channel(Providers.twitch, "123", "Bar"));
    expect(a.hashCode, Channel(Providers.twitch, "123", "Bar").hashCode);
  });

  test("profilePictureUrl uses the channel's provider and id", () {
    expect(Channel(Providers.twitch, "123", "Foo").profilePictureUrl.toString(),
        "https://rtirl.com/pfp.png?provider=twitch&channelId=123");
    expect(Channel(Providers.kick, "9", "Foo").profilePictureUrl.toString(),
        "https://rtirl.com/pfp.png?provider=kick&channelId=9");
  });

  test("toJson", () {
    expect(Channel("twitch", "123", "Foo", language: "en").toJson(), {
      "provider": "twitch",
      "channelId": "123",
      "displayName": "Foo",
      "language": "en",
    });
  });
}
