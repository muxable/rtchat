import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/views.dart';

import '../fakes/fake_user_model.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');
final other = Channel(Providers.twitch, '3', 'someone', language: 'ja');

void main() {
  test("shows the signed-in user's channel by default", () {
    final views = ViewsModel()..update(FakeUserModel(userChannel: kick));
    expect(views.activeView.id, ViewsModel.myChannelsId);
    expect(views.activeView.channels, [kick]);
    expect(views.primaryChannel, kick);
  });

  test("signed-out users start with nothing to show", () {
    final views = ViewsModel()..update(FakeUserModel());
    expect(views.primaryChannel, isNull);
  });

  test("my channel follows the signed-in account, notifying on change", () {
    var notifications = 0;
    final views = ViewsModel()..addListener(() => notifications++);
    views.update(FakeUserModel(userChannel: twitch));
    views.update(FakeUserModel(userChannel: twitch));
    expect(notifications, 1);
    views.update(FakeUserModel());
    expect(notifications, 2);
    expect(views.activeView.channels, isEmpty);
  });

  test("my channel picks up a new display name or language, notifying", () {
    var notifications = 0;
    final views = ViewsModel()..update(FakeUserModel(userChannel: twitch));
    views.addListener(() => notifications++);
    views.update(
        FakeUserModel(userChannel: Channel(Providers.twitch, '1', 'renamed')));
    expect(views.activeView.channels.single.displayName, 'renamed');
    expect(notifications, 1);
    views.update(FakeUserModel(
        userChannel:
            Channel(Providers.twitch, '1', 'renamed', language: 'ja')));
    expect(views.activeView.channels.single.language, 'ja');
    expect(notifications, 2);
  });

  test("opening a channel shows just that channel until going back", () {
    final views = ViewsModel()..update(FakeUserModel(userChannel: twitch));
    views.openChannel(other);
    expect(views.activeView.channels, [other]);
    expect(views.primaryChannel, other);
    views.showMyChannels();
    expect(views.primaryChannel, twitch);
  });

  test("saved views can be shown, edited and deleted", () {
    final views = ViewsModel()..update(FakeUserModel(userChannel: twitch));
    final simulcast = views.saveView("Simulcast", [twitch, kick]);
    views.showView(simulcast.id);
    expect(views.activeView, simulcast);

    views.updateView(simulcast.copyWith(name: "IRL", channels: [kick]));
    expect(views.activeView.name, "IRL");
    expect(views.primaryChannel, kick);

    views.deleteView(simulcast.id);
    expect(views.savedViews, isEmpty);
    expect(views.activeView.id, ViewsModel.myChannelsId);
  });

  test("saved views and the active one survive a restart", () {
    final views = ViewsModel()..update(FakeUserModel(userChannel: twitch));
    final saved = views.saveView("Simulcast", [twitch, other]);
    views.showView(saved.id);
    // opened channels aren't remembered, like before views existed.
    final restored = ViewsModel.fromJson(
        jsonDecode(jsonEncode(views.toJson())) as Map<String, dynamic>);
    expect(restored.savedViews, [saved]);
    expect(restored.activeView, saved);
    expect(restored.activeView.channels.last.language, 'ja');
  });

  test("signed-out users can save and show views", () {
    final views = ViewsModel()..update(FakeUserModel());
    final simulcast = views.saveView("Simulcast", [twitch, kick]);
    views.showView(simulcast.id);
    expect(views.activeView.channels, [twitch, kick]);
    expect(views.primaryChannel, twitch);
  });

  test("a missing active view falls back to my channels", () {
    final restored = ViewsModel.fromJson({'views': [], 'activeViewId': 'gone'})
      ..update(FakeUserModel(userChannel: kick));
    expect(restored.activeView.id, ViewsModel.myChannelsId);
    expect(restored.primaryChannel, kick);
  });
}
