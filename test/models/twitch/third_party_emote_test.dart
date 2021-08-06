import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/messages/twitch/third_party_emote.dart';

void main() {
  test('bttv global has emotes', () async {
    final emotes = await getBttvGlobalEmotes();

    expect(emotes, isNotEmpty);
  });

  test('bttv channel has emotes', () async {
    final emotes = await getBttvChannelEmotes("158394109");

    expect(emotes, isNotEmpty);
  });

  test('ffz channel has emotes', () async {
    final emotes = await getFfzChannelEmotes("158394109");

    expect(emotes, isNotEmpty);
  });

  test('7tv global has emotes', () async {
    final emotes = await get7tvGlobalEmotes();

    expect(emotes, isNotEmpty);
  });
}
