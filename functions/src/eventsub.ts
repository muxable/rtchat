import * as admin from "firebase-admin";
import fetch from "cross-fetch";
import { ClientCredentials } from "simple-oauth2";
import {
  TWITCH_CLIENT_ID,
  TWITCH_CLIENT_SECRET,
  TWITCH_OAUTH_CONFIG,
} from "./oauth";

enum EventsubType {
  ChannelFollow = "channel.follow",
  ChannelSubscribe = "channel.subscribe",
  ChannelSubscriptionGift = "channel.subscription.gift",
  ChannelSubscriptionMessage = "channel.subscription.message",
  ChannelSubscriptionEnd = "channel.subscription.end",
  ChannelCheer = "channel.cheer",
  ChannelRaid = "channel.raid",
  ChannelBan = "channel.ban",
  ChannelUnban = "channel.unban",
  ChannelChannelPointsCustomRewardRedemptionAdd = "channel.channel_points_custom_reward_redemption.add",
  ChannelChannelPointsCustomRewardRedemptionUpdate = "channel.channel_points_custom_reward_redemption.update",
  ChannelPollBegin = "channel.poll.begin",
  ChannelPollProgress = "channel.poll.progress",
  ChannelPollEnd = "channel.poll.end",
  ChannelPredictionBegin = "channel.prediction.begin",
  ChannelPredictionProgress = "channel.prediction.progress",
  ChannelPredictionLock = "channel.prediction.lock",
  ChannelPredictionEnd = "channel.prediction.end",
  ChannelHypeTrainBegin = "channel.hype_train.begin",
  ChannelHypeTrainProgress = "channel.hype_train.progress",
  ChannelHypeTrainEnd = "channel.hype_train.end",
  ChannelUpdate = "channel.update",
  StreamOnline = "stream.online",
  StreamOffline = "stream.offline",
  ChannelShoutoutCreate = "channel.shoutout.create",
  ChannelShoutoutReceive = "channel.shoutout.receive",
}

// The subscriptions each channel needs. channel.raid is subscribed twice: to
// the channel for incoming raids, and from it for outgoing raid completion.
export function eventsubConditions(twitchUserId: string) {
  const subscriptions: { type: string; condition: any }[] = [];
  for (const type of Object.values(EventsubType)) {
    if (type === EventsubType.ChannelRaid) {
      subscriptions.push(
        { type, condition: { to_broadcaster_user_id: twitchUserId } },
        { type, condition: { from_broadcaster_user_id: twitchUserId } },
      );
    } else if (
      type === EventsubType.ChannelShoutoutCreate ||
      type === EventsubType.ChannelShoutoutReceive ||
      type === EventsubType.ChannelFollow
    ) {
      subscriptions.push({
        type,
        condition: {
          broadcaster_user_id: twitchUserId,
          moderator_user_id: twitchUserId,
        },
      });
    } else {
      subscriptions.push({
        type,
        condition: { broadcaster_user_id: twitchUserId },
      });
    }
  }
  return subscriptions;
}

// The raiding channel's id if the notification is for a raid out of the
// channel, null otherwise.
export function outgoingRaidFrom(subscription: any): string | null {
  if (subscription?.type !== EventsubType.ChannelRaid) {
    return null;
  }
  return subscription?.condition?.from_broadcaster_user_id || null;
}

function createEventsub(token: string, type: string, condition: any) {
  return fetch("https://api.twitch.tv/helix/eventsub/subscriptions", {
    method: "POST",
    headers: {
      "Client-ID": TWITCH_CLIENT_ID,
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      type,
      version: type === "channel.follow" ? "2" : "1",
      condition,
      transport: {
        method: "webhook",
        callback: "https://rtchat-api.rtirl.com/eventsub",
        secret: TWITCH_CLIENT_SECRET,
      },
    }),
  });
}

export async function checkEventSubSubscriptions(userId: string) {
  const credentials = await new ClientCredentials(TWITCH_OAUTH_CONFIG).getToken(
    { scopes: [] },
  );
  const appAccessToken = credentials.token.access_token;
  const snapshot = await admin
    .database()
    .ref("userIds")
    .child("twitch")
    .orderByValue()
    .equalTo(userId)
    .get();
  const twitchUserId = Object.keys(snapshot.val() || {})[0];
  if (!twitchUserId) {
    console.log("missing twitch user id");
    return;
  }
  for (const { type, condition } of eventsubConditions(twitchUserId)) {
    let response = await createEventsub(appAccessToken, type, condition);
    if (response.status == 409) {
      // subscription already exists, this is ok.
      console.log("subscription already exists", type, twitchUserId);
      continue;
    } else if (response.status != 202) {
      console.error(
        "failed to create subscription",
        type,
        await response.json(),
        response.status,
      );
      continue;
    }
    const json = await response.json();
    console.log("subscribing to", type, twitchUserId);
    console.log(JSON.stringify(json));
  }
}
