import * as functions from "firebase-functions";
import fetch from "cross-fetch";
import { ClientCredentials } from "simple-oauth2";
import { getAccessToken, TWITCH_CLIENT_ID, TWITCH_OAUTH_CONFIG } from "./oauth";
import { StaticAuthProvider } from "@twurple/auth";
import { ChatClient } from "@twurple/chat";

type Emote = {
  provider: "twitch" | "bttv" | "ffz" | "7tv";
  category: string | null;
  id: string;
  code: string;
  imageUrl: string;
};

type UnresolvedTwitchEmote = {
  provider: "twitch";
  channelId: string | null;
  id: string;
  code: string;
  imageUrl: string;
};

export async function getTwitchEmotes(
  accessToken: string | null
): Promise<Emote[]> {
  if (!accessToken) {
    // if unauthenticated, return no emotes. global emotes are resolved in-band.
    return [];
  }
  // the only way to reliably get twitch emotes is to connect via irc and pull the emote sets from the global state.
  const chatClient = new ChatClient({
    authProvider: new StaticAuthProvider(TWITCH_CLIENT_ID, accessToken),
  });
  const promise = new Promise<string[]>((resolve) => {
    chatClient.onAnyMessage((message) => {
      if (message.command === "GLOBALUSERSTATE") {
        resolve(message.tags.get("emote-sets")?.split(",") ?? []);
      }
    });
    chatClient.onDisconnect(() => resolve([]));
  });
  await chatClient.connect();
  const message = await promise;
  // batch into chunks of 25.
  const emotePromises: Promise<UnresolvedTwitchEmote[]>[] = [];
  for (let i = 0; i < message.length; i += 25) {
    const chunk = message.slice(i, i + 25);
    const param = chunk.map((id) => `emote_set_id=${id}`).join("&");
    const response = fetch(
      "https://api.twitch.tv/helix/chat/emotes/set?" + param,
      {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Client-Id": TWITCH_CLIENT_ID,
        },
      }
    )
      .then((res) => res.json() as any)
      .then((json) => {
        return json["data"].map((emote: any) => {
          let channelId = emote["owner_id"];
          if (channelId === "twitch" || channelId === "0") {
            channelId = null;
          }
          return {
            provider: "twitch",
            channelId,
            id: emote.id,
            code: emote["name"],
            imageUrl: json["template"]
              .replace("{{id}}", emote.id)
              .replace("{{format}}", "default")
              .replace("{{theme_mode}}", "dark")
              .replace("{{scale}}", emote["scale"].pop()),
          };
        });
      })
      .catch(() => []);
    emotePromises.push(response);
  }
  const unresolved = (await Promise.all(emotePromises)).flat();
  // collect the channel ids.
  const channelIds = Array.from(
    new Set(
      unresolved.map((emote) => emote.channelId).filter((id) => id !== null)
    )
  );
  const channelPromises: Promise<[string, string][]>[] = [];
  // batch user id requests into chunks of 100.
  for (let i = 0; i < channelIds.length; i += 100) {
    // get the channel ids for this chunk.
    const chunk = channelIds.slice(i, i + 100);
    const param = chunk.map((id) => `id=${id}`).join("&");
    const response = fetch("https://api.twitch.tv/helix/users?" + param, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Client-Id": TWITCH_CLIENT_ID,
      },
    })
      .then((res) => res.json() as any)
      .then((json) => {
        return json["data"].map((user: any) => [user.id, user.display_name]);
      });
    channelPromises.push(response);
  }
  const channels = new Map((await Promise.all(channelPromises)).flat());
  // resolve the unresolved emotes.
  return unresolved.map((emote) => {
    const channel = emote.channelId ? channels.get(emote.channelId) : null;
    return {
      provider: "twitch",
      category: channel ?? null,
      id: emote.id,
      code: emote.code,
      imageUrl: emote.imageUrl,
    };
  });
}

export async function getBTTVEmotes(channelId: string): Promise<Emote[]> {
  const global = fetch(`https://api.betterttv.net/3/cached/emotes/global`)
    .then((res) => res.json() as any)
    .then((json) =>
      json.map((emote: any) => ({
        provider: "bttv",
        category: null,
        id: emote.id,
        code: emote.code,
        imageUrl: `https://cdn.betterttv.net/emote/${emote.id}/3x`,
      }))
    )
    .catch(() => []);
  const local = fetch(
    `https://api.betterttv.net/3/cached/users/twitch/${channelId}`
  )
    .then((res) => res.json() as any)
    .then((json) => [
      ...json.channelEmotes.map((emote: any) => ({
        provider: "bttv",
        category: "Channel Emotes",
        id: emote.id,
        code: emote.code,
        imageUrl: `https://cdn.betterttv.net/emote/${emote.id}/3x`,
      })),
      ...json.sharedEmotes.map((emote: any) => ({
        provider: "bttv",
        category: "Shared Emotes",
        id: emote.id,
        code: emote.code,
        imageUrl: `https://cdn.betterttv.net/emote/${emote.id}/3x`,
      })),
    ])
    .catch(() => []);
  return Promise.all([global, local]).then(([global, local]) => [
    ...global,
    ...local,
  ]);
}

export async function getFFZEmotes(channelId: string): Promise<Emote[]> {
  const global = fetch("https://api.frankerfacez.com/v1/set/global")
    .then((res) => res.json() as any)
    .then((json) =>
      json["default_sets"].flatMap((set: number) => {
        return json["sets"][set]["emoticons"].map((emote: any) => {
          return {
            provider: "ffz",
            category: json["sets"][set]["title"],
            id: emote["id"],
            code: emote["name"],
            imageUrl:
              emote["urls"]["4"] || emote["urls"]["2"] || emote["urls"]["1"],
          };
        });
      })
    )
    .catch(() => []);
  const local = fetch(`https://api.frankerfacez.com/v1/room/id/${channelId}`)
    .then((res) => res.json() as any)
    .then((json) =>
      json["sets"][json["room"]["set"]]["emoticons"].map((emote: any) => {
        return {
          provider: "ffz",
          category: json["sets"][json["room"]["set"]]["title"],
          id: emote["id"],
          code: emote["name"],
          imageUrl:
            emote["urls"]["4"] || emote["urls"]["2"] || emote["urls"]["1"],
        };
      })
    )
    .catch(() => []);
  return Promise.all([global, local]).then(([global, local]) => [
    ...global,
    ...local,
  ]);
}

export async function get7TVEmotes(channelId: string): Promise<Emote[]> {
  const global = fetch("https://api.7tv.app/v2/emotes/global")
    .then((res) => res.json() as any)
    .then((json) =>
      json.map((emote: any) => ({
        provider: "7tv",
        category: null,
        id: emote.id,
        code: emote.name,
        imageUrl: emote.urls.pop()[1],
      }))
    )
    .catch(() => []);
  const local = fetch(`https://api.7tv.app/v2/users/${channelId}/emotes`)
    .then((res) => res.json() as any)
    .then((json) =>
      json.map((emote: any) => ({
        provider: "7tv",
        category: null,
        id: emote.id,
        code: emote.name,
        imageUrl: emote.urls.pop()[1],
      }))
    )
    .catch(() => []);
  return Promise.all([global, local]).then(([global, local]) => [
    ...global,
    ...local,
  ]);
}

async function getToken(
  context: functions.https.CallableContext,
  provider: string
) {
  const uid = context.auth?.uid;
  if (!uid) {
    return null;
  }
  return await getAccessToken(uid, provider);
}

export const getEmotes = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }
  const token = await getToken(context, provider);
  switch (provider) {
    case "twitch":
      const emotes = await Promise.all([
        getTwitchEmotes(token),
        getBTTVEmotes(channelId),
        getFFZEmotes(channelId),
        get7TVEmotes(channelId),
      ]);
      return emotes.flat();
  }
  return [];
});

export const getUserEmotes = functions.https.onCall(async (data, context) => {
  const provider = data?.provider;
  const channelId = data?.channelId;
  if (!provider || !channelId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "missing provider, channelId"
    );
  }

  switch (provider) {
    case "twitch":
      const credentials = await new ClientCredentials(
        TWITCH_OAUTH_CONFIG
      ).getToken({ scopes: [] });

      const channelJson = await getChannelEmotes(
        channelId,
        credentials.token.access_token
      );
      const globalEmotes = await getGlobalEmotes(
        credentials.token.access_token
      );
      const mappedChannelEmotes = mapEmotes(channelJson.data);
      const mappedGlobalEmotes = mapEmotes(globalEmotes.data);
      return { emotes: mappedGlobalEmotes.concat(mappedChannelEmotes) };
  }

  throw new functions.https.HttpsError("invalid-argument", "invalid provider");
});

function mapEmotes(emoteArray: any) {
  return emoteArray.map((emote: any) => {
    return {
      id: emote["id"],
      code: emote["name"],
      source: `https://static-cdn.jtvnw.net/emoticons/v2/${emote["id"]}/default/dark/1.0`,
    };
  });
}

async function getChannelEmotes(channelId: string, accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/emotes?broadcaster_id=" +
      encodeURIComponent(channelId),
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return (await twitchResponse.json()) as any;
}

async function getGlobalEmotes(accessToken: string) {
  const twitchResponse = await fetch(
    "https://api.twitch.tv/helix/chat/emotes/global",
    {
      headers: {
        "Client-ID": TWITCH_CLIENT_ID,
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
    }
  );
  return (await twitchResponse.json()) as any;
}
