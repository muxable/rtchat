import { describe, expect, it } from "vitest";
import { checkUnlink, linkedProviders, resolveLink } from "../src/accounts";

const twitch = { id: "1", login: "muxfd" };
const kick = { id: "2", slug: "muxfd" };

describe("linkedProviders", () => {
  it("lists accounts with an id", () => {
    expect(linkedProviders({ twitch, kick, lastActiveAt: 1 })).toEqual([
      "twitch",
      "kick",
    ]);
    expect(linkedProviders({ twitch: null })).toEqual([]);
    expect(linkedProviders(undefined)).toEqual([]);
  });
});

describe("resolveLink", () => {
  it("signs in or creates users when not linking", () => {
    expect(resolveLink(null, null)).toBe("create");
    expect(resolveLink("uid-a", null)).toBe("existing");
  });

  it("links unmapped or already-owned accounts to the signed-in user", () => {
    expect(resolveLink(null, "uid-a")).toBe("link");
    expect(resolveLink("uid-a", "uid-a")).toBe("link");
  });

  it("refuses accounts that belong to someone else", () => {
    expect(resolveLink("uid-b", "uid-a")).toBe("conflict");
  });
});

describe("checkUnlink", () => {
  it("allows unlinking when another account remains", () => {
    expect(checkUnlink({ twitch, kick }, "kick")).toBe("ok");
    expect(checkUnlink({ twitch, kick }, "twitch")).toBe("ok");
  });

  it("refuses the last account and unlinked providers", () => {
    expect(checkUnlink({ kick }, "kick")).toBe("last-account");
    expect(checkUnlink({ twitch }, "kick")).toBe("not-linked");
  });
});
