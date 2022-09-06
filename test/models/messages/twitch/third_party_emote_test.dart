import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';

void main() {
  test('channel has emotes', () async {
    final emotes = await getEmotes(Channel("twitch", "158394109", "muxfd"));

    expect(emotes, isNotEmpty);
  });
}
