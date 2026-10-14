import fetch from "cross-fetch";

const CHANNEL_ID_PATTERN = /^UC[A-Za-z0-9_-]{22}$/;
const HANDLE_PATTERN = /^@?([A-Za-z0-9_.-]+)$/;

export function isYouTubeChannelId(value: unknown): value is string {
  return typeof value === "string" && CHANNEL_ID_PATTERN.test(value);
}

// The player for a channel's current live stream, muted like the other embeds.
export function youTubeEmbedUrl(channelId: string): string | null {
  if (!isYouTubeChannelId(channelId)) {
    return null;
  }
  return `https://www.youtube.com/embed/live_stream?channel=${channelId}&autoplay=1&mute=1`;
}

export function parseYouTubeQuery(
  query: string
): { channelId: string } | { handle: string } | null {
  let value = query.trim();
  if (/^(https?:\/\/)?(www\.|m\.)?youtube\.com\//i.test(value)) {
    try {
      const url = new URL(
        /^https?:\/\//i.test(value) ? value : `https://${value}`
      );
      const path = decodeURIComponent(url.pathname).replace(/\/$/, "");
      if (path.startsWith("/channel/")) {
        const channelId = path.slice("/channel/".length);
        return isYouTubeChannelId(channelId) ? { channelId } : null;
      }
      if (!path.startsWith("/@")) {
        return null;
      }
      value = path.slice(1);
    } catch {
      return null;
    }
  }
  if (isYouTubeChannelId(value)) {
    return { channelId: value };
  }
  const match = HANDLE_PATTERN.exec(value);
  return match ? { handle: match[1].toLowerCase() } : null;
}

export interface YouTubeLookupCache {
  get(key: string): Promise<YouTubeSearchResult[] | undefined>;
  set(key: string, results: YouTubeSearchResult[]): Promise<void>;
}

export type YouTubeSearchResult = Awaited<
  ReturnType<typeof lookupYouTubeChannel>
>[number];

// Every search spends quota otherwise, so lookups (including misses) are cached.
export async function searchYouTubeChannel(
  apiKey: string,
  query: string,
  cache?: YouTubeLookupCache
) {
  const lookup = parseYouTubeQuery(query);
  if (!lookup || !apiKey) {
    return [];
  }
  const key = "channelId" in lookup ? lookup.channelId : `@${lookup.handle}`;
  const cached = await cache?.get(key).catch(() => undefined);
  if (cached) {
    return cached;
  }
  const results = await lookupYouTubeChannel(apiKey, lookup);
  await cache?.set(key, results).catch(() => undefined);
  return results;
}

// Exact channels.list lookups cost one quota unit; never use search.list.
async function lookupYouTubeChannel(
  apiKey: string,
  lookup: { channelId: string } | { handle: string }
) {
  const params = new URLSearchParams({ part: "snippet", key: apiKey });
  if ("channelId" in lookup) {
    params.set("id", lookup.channelId);
  } else {
    params.set("forHandle", `@${lookup.handle}`);
  }
  try {
    const response = await fetch(
      `https://www.googleapis.com/youtube/v3/channels?${params}`
    );
    if (!response.ok) {
      return [];
    }
    const json = await response.json();
    const channel = json.items?.[0];
    if (!channel || !isYouTubeChannelId(channel.id) || !channel.snippet) {
      return [];
    }
    const snippet = channel.snippet;
    // Older channels may not expose a handle; keep their id as the fallback.
    const login =
      snippet.customUrl || ("handle" in lookup ? lookup.handle : channel.id);
    return [
      {
        provider: "youtube",
        channelId: channel.id,
        login: login.replace(/^@/, "").toLowerCase(),
        displayName: snippet.title,
        imageUrl:
          snippet.thumbnails?.default?.url ||
          snippet.thumbnails?.medium?.url ||
          "",
        isOnline: false,
      },
    ];
  } catch {
    return [];
  }
}
