import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/models/channels.dart';

// This is the very first time I write a test in flutter. take it easy on me plz! :D
void main() {
  test('Create Channels Test', () {
    var channel1 = Channel("provider", "channelId", "displayName");
    var channel2 = Channel("provider", "channelId", "another_display_name");
    var channel3 = Channel("another_provider", "channelId", "displayName");
    var channel4 = Channel("provider", "another_channelId", "displayName");
    assert(channel1 == channel2);
    assert(channel1 != channel3);
    assert(channel1 != channel4);
  });

  test("Channel Models Test", () {
    var channel1 = Channel("sam", "1", "ch1");
    var channel2 = Channel("sam", "1", "ch2");
    var channel3 = Channel("george", "1", "ch1");
    var channel4 = Channel("sam", "2", "ch1");

    var host = ChannelsModel();
    host.addAvailableChannel(channel1);
    host.addAvailableChannel(channel2);
    host.addAvailableChannel(channel3);
    host.addAvailableChannel(channel4);
    assert(host.availableChannels.length == 3);

    var newChannel = Channel("provider", "channelId", "displayName");

    host.subscribedChannels = {channel1, newChannel};
    assert(host.subscribedChannels.length == 1);
  });
}
