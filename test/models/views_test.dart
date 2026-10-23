import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_accounts.dart';
import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');
final other = Channel(Providers.twitch, '3', 'someone', language: 'ja');
final otherKick = Channel(Providers.kick, '4', 'friend');

ViewsModel signedInAs(Channel? channel) =>
    ViewsModel()..update(FakeUserModel(userChannel: channel));

FakeUserModel signedInToAll(List<Channel> channels) => FakeUserModel(
  accounts: [for (final channel in channels) fakeAccount(channel)],
);

ViewsModel restart(ViewsModel views) => ViewsModel.fromJson(
  jsonDecode(jsonEncode(views.toJson())) as Map<String, dynamic>,
);

void main() {
  group("default channels", () {
    test("are the signed-in user's channel until picked", () {
      final views = signedInAs(kick);
      expect(views.defaultChannels, [kick]);
      expect(views.channels, [kick]);
      expect(views.primaryChannel, kick);
    });

    test("are all of the signed-in user's channels until picked", () {
      final views = ViewsModel()..update(signedInToAll([twitch, kick]));
      expect(views.defaultChannels, [twitch, kick]);
      expect(views.channels, [twitch, kick]);
      expect(views.hasCustomDefaultChannels, isFalse);
    });

    test("follow accounts being added and removed", () {
      var notifications = 0;
      final views = signedInAs(twitch)..addListener(() => notifications++);
      views.update(signedInToAll([twitch, kick]));
      expect(views.channels, [twitch, kick]);
      views.update(signedInToAll([twitch, kick]));
      expect(notifications, 1);
      views.update(signedInToAll([kick]));
      expect(views.channels, [kick]);
      expect(notifications, 2);
    });

    test("are empty for signed-out users until picked", () {
      final views = signedInAs(null);
      expect(views.defaultChannels, isEmpty);
      expect(views.primaryChannel, isNull);
    });

    test("can be added to, removed from and replaced", () {
      final views = signedInAs(twitch);
      views.addDefaultChannel(kick);
      expect(views.defaultChannels, [twitch, kick]);
      views.addDefaultChannel(kick);
      expect(views.defaultChannels, [twitch, kick]);
      views.removeDefaultChannel(twitch);
      expect(views.defaultChannels, [kick]);
      // removing the last one goes back to the user's channel.
      views.removeDefaultChannel(kick);
      expect(views.defaultChannels, [twitch]);
      expect(views.hasCustomDefaultChannels, isFalse);
    });

    test("can be copied from the current channels", () {
      final views =
          signedInAs(twitch)
            ..openChannel(other)
            ..addChannel(kick);
      views.useCurrentChannelsAsDefault();
      expect(views.defaultChannels, [other, kick]);
    });

    test("are what the app opens with after a restart", () {
      final views =
          signedInAs(twitch)
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
      views.addDefaultChannel(otherKick);
      expect(views.channels, [twitch]);
      views.showDefaultChannels();
      expect(views.channels, [twitch, otherKick]);
    });

    test("old saved views are ignored", () {
      final restored = ViewsModel.fromJson({
        'views': [
          {
            'id': 'simulcast',
            'name': 'Simulcast',
            'channels': [twitch.toJson(), kick.toJson()],
          },
        ],
        'activeViewId': 'simulcast',
      })..update(FakeUserModel(userChannel: kick));
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
      views.update(
        FakeUserModel(userChannel: Channel(Providers.twitch, '1', 'renamed')),
      );
      expect(views.channels.single.displayName, 'renamed');
      expect(notifications, 1);
      views.update(
        FakeUserModel(
          userChannel: Channel(
            Providers.twitch,
            '1',
            'renamed',
            language: 'ja',
          ),
        ),
      );
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
      final views = signedInAs(twitch)..addChannel(kick);
      views.removeChannel(twitch);
      expect(views.channels, [kick]);
      expect(views.primaryChannel, kick);
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

  group("preview", () {
    test("is of the first channel unless another was picked", () {
      final views = signedInAs(twitch)..addChannel(kick);
      expect(views.previewChannel, twitch);
      views.previewChannel = kick;
      expect(views.previewChannel, kick);
      views.openChannel(other);
      expect(views.previewChannel, other);
      // picked again once it's shown again.
      views.addChannel(kick);
      expect(views.previewChannel, kick);
    });

    test("falls back when the picked channel is removed", () {
      final views =
          signedInAs(twitch)
            ..addChannel(kick)
            ..previewChannel = kick;
      views.removeChannel(kick);
      expect(views.previewChannel, twitch);
    });
  });

  group("one channel per provider", () {
    test("adding a channel replaces the one on its provider, in place", () {
      var notifications = 0;
      final views =
          signedInAs(twitch)
            ..addChannel(kick)
            ..addListener(() => notifications++);
      views.addChannel(other);
      expect(views.channels, [other, kick]);
      views.addChannel(otherKick);
      expect(views.channels, [other, otherKick]);
      expect(notifications, 2);
    });

    test("the channel a channel would replace", () {
      final channels = [twitch, kick];
      expect(channelReplacedBy(channels, other), twitch);
      expect(channelReplacedBy(channels, otherKick), kick);
      // not itself.
      expect(channelReplacedBy(channels, kick), isNull);
      expect(channelReplacedBy([twitch], kick), isNull);
    });

    test("so does adding a default channel", () {
      final views = signedInAs(twitch);
      // the user's own channel is the default until others are picked.
      views.addDefaultChannel(other);
      expect(views.defaultChannels, [other]);
      views.addDefaultChannel(kick);
      views.addDefaultChannel(otherKick);
      expect(views.defaultChannels, [other, otherKick]);
    });

    test("default channels set together keep the first of each provider", () {
      final views = signedInAs(twitch);
      views.defaultChannels = [kick, twitch, otherKick, other];
      expect(views.defaultChannels, [kick, twitch]);
    });

    test("saved defaults keep the first channel of each provider", () {
      final restored = ViewsModel.fromJson({
        'defaultChannels': [
          kick.toJson(),
          twitch.toJson(),
          otherKick.toJson(),
          other.toJson(),
        ],
      });
      expect(restored.defaultChannels, [kick, twitch]);
      expect(restored.channels, [kick, twitch]);
      expect(restored.toJson()['defaultChannels'], [
        kick.toJson(),
        twitch.toJson(),
      ]);
    });
  });

  group("messages are sent", () {
    test("to the channels shown on a provider the user has an account on", () {
      final views =
          signedInAs(kick)
            ..openChannel(twitch)
            ..addChannel(kick);
      expect(views.sendableChannels, [kick]);
    });

    test("to every channel shown with accounts on all their providers", () {
      final views = ViewsModel()..update(signedInToAll([twitch, kick]));
      expect(views.sendableChannels, [twitch, kick]);
      // accounts can chat in others' channels on their provider.
      views.addChannel(otherKick);
      expect(views.sendableChannels, [twitch, otherKick]);
    });

    test("nowhere when no channel shown is on an account's provider", () {
      final views = signedInAs(kick)..openChannel(twitch);
      expect(views.sendableChannels, isEmpty);
      expect(signedInAs(null).sendableChannels, isEmpty);
    });

    test("to the channel opened, like before views", () {
      final views = signedInAs(twitch)..openChannel(other);
      expect(views.sendableChannels, [other]);
    });
  });

  group("the channel sent to", () {
    test("is the first sendable channel until another is picked", () {
      final views = ViewsModel()..update(signedInToAll([twitch, kick]));
      expect(views.sendChannel, twitch);
      views.sendChannel = kick;
      expect(views.sendChannel, kick);
    });

    test("is the one picked while it's sendable", () {
      var notifications = 0;
      final views =
          ViewsModel()
            ..update(signedInToAll([twitch, kick]))
            ..sendChannel = kick
            ..addListener(() => notifications++);
      views.removeChannel(kick);
      expect(views.sendChannel, twitch);
      // picked again once it's shown again.
      views.addChannel(kick);
      expect(views.sendChannel, kick);
      views.sendChannel = kick;
      expect(notifications, 2);
    });

    test("is none when nothing shown can be sent to", () {
      final views = signedInAs(kick)..openChannel(twitch);
      expect(views.sendChannel, isNull);
    });

    test("is remembered across a restart", () {
      final views =
          ViewsModel()
            ..update(signedInToAll([twitch, kick]))
            ..sendChannel = kick;
      final restored = restart(views)..update(signedInToAll([twitch, kick]));
      expect(restored.sendChannel, kick);
    });
  });
}
