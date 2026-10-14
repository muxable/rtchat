import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/channels.dart';

final twitch = Channel(Providers.twitch, '1', 'muxfd');
final kick = Channel(Providers.kick, '2', 'muxfd');

void main() {
  test("twitch channels always have follower counts", () {
    final metadata = channelMetadataFromData(twitch, {
      'viewerCount': 10,
      'language': 'en',
      'title': 'irl',
    }) as TwitchChannelMetadata;
    expect(metadata.viewerCount, 10);
    expect(metadata.followerCount, 0);
    expect(metadata.title, 'irl');
    expect(metadata.onlineAt, isNull);
  });

  test("kick channels report what kick provides", () {
    final online = DateTime(2025, 1, 1);
    final metadata = channelMetadataFromData(kick, {
      'viewerCount': 42,
      'language': 'en',
      'onlineAt': Timestamp.fromDate(online),
    });
    expect(metadata, isA<KickChannelMetadata>());
    expect(metadata, isA<StreamChannelMetadata>());
    final kickMetadata = metadata as KickChannelMetadata;
    expect(kickMetadata.viewerCount, 42);
    expect(kickMetadata.language, 'en');
    // kick doesn't report followers.
    expect(kickMetadata.followerCount, isNull);
    expect(kickMetadata.onlineAt, online);
  });

  test("channels without a document are offline", () {
    final metadata = channelMetadataFromData(kick, null);
    expect(metadata, isNot(isA<StreamChannelMetadata>()));
    expect(metadata.onlineAt, isNull);
  });
}
