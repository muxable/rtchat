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
    test("are the signed-in user's channel", () {
      final views = signedInAs(kick);
      expect(views.defaultChannels, [kick]);
      expect(views.channels, [kick]);
      expect(views.primaryChannel, kick);
    });

    test("are all of the signed-in accounts' channels, in order", () {
      final views = ViewsModel()..update(signedInToAll([twitch, kick]));
      expect(views.defaultChannels, [twitch, kick]);
      expect(views.channels, [twitch, kick]);
      expect(views.primaryChannel, twitch);
    });

    test("follow accounts being signed in to and out of", () {
      var notifications = 0;
      final views = signedInAs(twitch)..addListener(() => notifications++);
      views.update(signedInToAll([twitch, kick]));
      expect(views.channels, [twitch, kick]);
      views.update(signedInToAll([twitch, kick]));
      expect(notifications, 1);
      views.update(signedInToAll([kick]));
      expect(views.channels, [kick]);
      expect(notifications, 2);
      views.update(FakeUserModel());
      expect(views.channels, isEmpty);
    });

    test("are empty for signed-out users", () {
      final views = signedInAs(null);
      expect(views.defaultChannels, isEmpty);
      expect(views.primaryChannel, isNull);
    });

    test("are what the app opens with after a restart", () {
      final views = ViewsModel()..update(signedInToAll([twitch, kick]));
      views.openChannel(other);
      final restored = restart(views)..update(signedInToAll([twitch, kick]));
      expect(restored.channels, [twitch, kick]);
    });

    test("can be gone back to after changing channels", () {
      final views = signedInAs(twitch)..openChannel(other);
      views.update(signedInToAll([twitch, kick]));
      // channels picked during the session stay until gone back.
      expect(views.channels, [other]);
      views.showDefaultChannels();
      expect(views.channels, [twitch, kick]);
    });

    test("picked before are ignored and dropped", () {
      final restored = ViewsModel.fromJson({
        'defaultChannels': [other.toJson(), otherKick.toJson()],
      })..update(FakeUserModel(userChannel: twitch));
      expect(restored.defaultChannels, [twitch]);
      expect(restored.channels, [twitch]);
      expect(restored.toJson().containsKey('defaultChannels'), isFalse);
      expect(
        ViewsModel.fromJson({'defaultChannels': 'junk'}).channels,
        isEmpty,
      );
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

    test("the signed-in accounts' channels keep one per provider", () {
      final views =
          ViewsModel()..update(signedInToAll([kick, twitch, otherKick, other]));
      expect(views.defaultChannels, [kick, twitch]);
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
