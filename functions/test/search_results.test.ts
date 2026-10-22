import { describe, expect, it } from "vitest";
import { exactMatchesFirst } from "../src/search_results";

describe("exactMatchesFirst", () => {
  it("moves channels whose login is the query to the top", () => {
    const results = [
      { provider: "twitch", login: "n3on_dj" },
      { provider: "twitch", login: "n3onz1" },
      { provider: "kick", login: "n3on" },
      { provider: "youtube", login: "n3on" },
    ];
    expect(exactMatchesFirst(results, "N3on").map((r) => r.login)).toEqual([
      "n3on",
      "n3on",
      "n3on_dj",
      "n3onz1",
    ]);
  });

  it.each(["@N3on", "https://youtube.com/@N3on"])(
    "prioritizes a YouTube handle in %s",
    (query) => {
      const results = [
        { provider: "twitch", login: "n3on_dj" },
        { provider: "youtube", login: "n3on" },
      ];
      expect(exactMatchesFirst(results, query)).toEqual([
        results[1],
        results[0],
      ]);
    },
  );

  it("keeps the order of the other results", () => {
    const results = [
      { provider: "twitch", login: "xqc" },
      { provider: "twitch", login: "xqcshadow" },
      { provider: "kick", login: "xqc" },
    ];
    expect(exactMatchesFirst(results, "xqc")).toEqual([
      { provider: "twitch", login: "xqc" },
      { provider: "kick", login: "xqc" },
      { provider: "twitch", login: "xqcshadow" },
    ]);
  });
});
