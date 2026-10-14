import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');
final other = Channel(Providers.twitch, '3', 'someone', language: 'ja');
final otherKick = Channel(Providers.kick, '4', 'friend');

ViewsModel signedInAs(Channel? channel) =>
    ViewsModel()..update(FakeUserModel(userChannel: channel));

ViewsModel restart(ViewsModel views) => ViewsModel.fromJson(
    jsonDecode(jsonEncode(views.toJson())) as Map<String, dynamic>);

void main() {
  group("default channels", () {
    test("are the signed-in user's channel until picked", () {
      final views = signedInAs(kick);
      expect(views.defaultChannels, [kick]);
      expect(views.channels, [kick]);
      expect(views.primaryChannel, kick);
    });

    test("never combine the user's accounts on different platforms", () {
      final views = ViewsModel()
        ..update(
            FakeUserModel(userChannel: twitch, userChannels: [twitch, kick]));
      expect(views.channels, [twitch]);
    });

    test("are empty for signed-out users until picked", () {
      final views = signedInAs(null);
      expect(views.defaultChannels, isEmpty);
      expect(views.primaryChannel, isNull);
    });

    test("can be added to, removed from and replaced", () {
      final views = signedInAs(twitch);
      views.addDefaultChannel(other);
      expect(views.defaultChannels, [twitch, other]);
      views.addDefaultChannel(other);
      expect(views.defaultChannels, [twitch, other]);
      views.removeDefaultChannel(twitch);
      expect(views.defaultChannels, [other]);
      // removing the last one goes back to the user's channel.
      views.removeDefaultChannel(other);
      expect(views.defaultChannels, [twitch]);
      expect(views.hasCustomDefaultChannels, isFalse);
    });

    test("can be copied from the current channels", () {
      final views = signedInAs(twitch)
        ..openChannel(other)
        ..addChannel(kick);
      views.useCurrentChannelsAsDefault();
      expect(views.defaultChannels, [other, kick]);
    });

    test("are what the app opens with after a restart", () {
      final views = signedInAs(twitch)
        ..addDefaultChannel(kick)
        ..addChannel(other);
      final restored = restart(views)
        ..update(FakeUserModel(userChannel: twitch));
      expect(restored.defaultChannels, [twitch, kick]);
      expect(restored.channels, [twitch, kick]);
      expect(restored.channels.first.displayName, 'muxfd');
    });

    test("keep a channel's language across a restart", () {
      final views = signedInAs(null)..addDefaultChannel(other);
      expect(restart(views).channels.single.language, 'ja');
    });

    test("the current channels follow the defaults until changed", () {
      final views = signedInAs(twitch);
      views.addDefaultChannel(kick);
      expect(views.channels, [twitch, kick]);
      views.removeChannel(kick);
      views.addDefaultChannel(other);
      expect(views.channels, [twitch]);
      views.showDefaultChannels();
      expect(views.channels, [twitch, kick, other]);
    });

    test("old saved views are ignored", () {
      final restored = ViewsModel.fromJson({
        'views': [
          {
            'id': 'simulcast',
            'name': 'Simulcast',
            'channels': [twitch.toJson(), kick.toJson()],
          }
        ],
        'activeViewId': 'simulcast',
      })
        ..update(FakeUserModel(userChannel: kick));
      expect(restored.channels, [kick]);
      expect(restored.toJson().containsKey('views'), isFalse);
    });
  });

  group("current channels", () {
    test("follow the signed-in account, notifying on change", () {
      var notifications = 0;
      final views = ViewsModel()..addListener(() => notifications++);
      views.update(FakeUserModel(userChannel: twitch));
      views.update(FakeUserModel(userChannel: twitch));
      expect(notifications, 1);
      views.update(FakeUserModel());
      expect(notifications, 2);
      expect(views.channels, isEmpty);
    });

    test("pick up a new display name or language, notifying", () {
      var notifications = 0;
      final views = signedInAs(twitch)..addListener(() => notifications++);
      views.update(FakeUserModel(
          userChannel: Channel(Providers.twitch, '1', 'renamed')));
      expect(views.channels.single.displayName, 'renamed');
      expect(notifications, 1);
      views.update(FakeUserModel(
          userChannel:
              Channel(Providers.twitch, '1', 'renamed', language: 'ja')));
      expect(views.channels.single.language, 'ja');
      expect(notifications, 2);
    });

    test("opening a channel shows just that channel", () {
      final views = signedInAs(twitch)..addChannel(kick);
      views.openChannel(other);
      expect(views.channels, [other]);
      expect(views.primaryChannel, other);
    });

    test("channels can be added once", () {
      var notifications = 0;
      final views = signedInAs(twitch)..addListener(() => notifications++);
      views.addChannel(kick);
      views.addChannel(kick);
      expect(views.channels, [twitch, kick]);
      expect(notifications, 1);
      expect(views.contains(kick), isTrue);
      expect(views.contains(other), isFalse);
    });

    test("removing channels keeps at least one", () {
      final views = signedInAs(twitch)
        ..addChannel(kick)
        ..addChannel(other);
      views.removeChannel(twitch);
      expect(views.channels, [kick, other]);
      expect(views.primaryChannel, kick);
      views.removeChannel(other);
      expect(views.channels, [kick]);
      views.removeChannel(kick);
      expect(views.channels, [kick]);
    });

    test("aren't remembered across a restart", () {
      final views = signedInAs(twitch)..openChannel(other);
      final restored = restart(views)
        ..update(FakeUserModel(userChannel: twitch));
      expect(restored.channels, [twitch]);
    });
  });
}
