import { beforeEach, describe, expect, it, vi } from "vitest";

const { fetchMock } = vi.hoisted(() => ({ fetchMock: vi.fn() }));
vi.mock("cross-fetch", () => ({ default: fetchMock }));

import { kickApi } from "../src/kick";
function jsonResponse(status: number, body: unknown) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => body,
    text: async () => JSON.stringify(body),
  };
}

beforeEach(() => fetchMock.mockReset());

describe("kickApi", () => {
  it("sends the bearer token and parses json", async () => {
    fetchMock.mockResolvedValue(jsonResponse(200, { data: [1] }));
    await expect(kickApi("tok", "/users")).resolves.toEqual({ data: [1] });
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://api.kick.com/public/v1/users");
    expect(init.headers.Authorization).toBe("Bearer tok");
  });

  it("returns null for 204 and throws on errors", async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse(204, null));
    await expect(
      kickApi("tok", "/chat/1", { method: "DELETE" })
    ).resolves.toBeNull();
    fetchMock.mockResolvedValueOnce(jsonResponse(401, { message: "nope" }));
    await expect(kickApi("tok", "/users")).rejects.toThrow(/401/);
  });
});
