import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/profiles.dart';
import 'package:rtchat/models/channels.dart';

void main() {
  test("a twitch profile has its twitch channel", () {
    expect(
        channelFromProfile({
          'twitch': {'id': '123', 'displayName': 'Muxfd', 'login': 'muxfd'},
          'lastActiveAt': null,
        }),
        Channel(Providers.twitch, '123', 'Muxfd'));
  });

  test("a kick profile has its kick channel", () {
    final channel = channelFromProfile({
      'kick': {'id': 9, 'slug': 'muxfd', 'displayName': 'MuxFD'},
    });
    expect(channel, Channel(Providers.kick, '9', 'MuxFD'));
    expect(channel?.displayName, 'MuxFD');
  });

  test("falls back to the slug for the display name", () {
    expect(
        channelFromProfile({
          'kick': {'id': 9, 'slug': 'muxfd'},
        })?.displayName,
        'muxfd');
  });

  test("a missing account has no channel", () {
    expect(channelFromProfile(null), isNull);
    expect(channelFromProfile({'twitch': null, 'claims': {}}), isNull);
  });
}
