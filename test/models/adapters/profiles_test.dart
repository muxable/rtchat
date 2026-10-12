import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';

void main() {
  test("a twitch-only profile has one channel", () {
    expect(
        channelsFromProfile({
          'twitch': {'id': '123', 'displayName': 'Muxfd', 'login': 'muxfd'},
          'lastActiveAt': null,
        }),
        [Channel(Providers.twitch, '123', 'Muxfd')]);
  });

  test("linked accounts are listed twitch first", () {
    final channels = channelsFromProfile({
      'kick': {'id': '9', 'slug': 'muxfd', 'displayName': 'MuxFD'},
      'twitch': {'id': '123', 'displayName': 'Muxfd'},
    });
    expect(channels, [
      Channel(Providers.twitch, '123', 'Muxfd'),
      Channel(Providers.kick, '9', 'MuxFD'),
    ]);
    expect(channels[1].displayName, 'MuxFD');
  });

  test("a kick-only profile has its kick channel", () {
    expect(
        channelsFromProfile({
          'kick': {'id': 9, 'slug': 'muxfd'},
        }),
        [Channel(Providers.kick, '9', 'muxfd')]);
  });

  test("missing or unlinked accounts are skipped", () {
    expect(channelsFromProfile(null), isEmpty);
    expect(channelsFromProfile({'twitch': null, 'claims': {}}), isEmpty);
  });
}
