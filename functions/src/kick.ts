import fetch from "cross-fetch";

// Kick's public API: https://docs.kick.com/
export const KICK_API = "https://api.kick.com/public/v1";

export async function kickApi(
  accessToken: string,
  path: string,
  init: RequestInit = {}
) {
  const response = await fetch(`${KICK_API}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      ...(init.body ? { "Content-Type": "application/json" } : {}),
      ...init.headers,
    },
  });
  if (!response.ok) {
    throw new Error(
      `kick api ${init.method ?? "GET"} ${path}: ${
        response.status
      } ${await response.text()}`
    );
  }
  return response.status === 204 ? null : await response.json();
}
