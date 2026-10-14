import { parseYouTubeQuery } from "./youtube";

// Channels whose login is exactly the query go first, so an exact kick match
// or YouTube match isn't buried under Twitch's fuzzy results.
export function exactMatchesFirst<T extends { login: string }>(
  results: T[],
  query: string
) {
  const lookup = parseYouTubeQuery(query);
  const wanted =
    lookup && "handle" in lookup ? lookup.handle : query.trim().toLowerCase();
  const isExact = (result: T) => result.login?.toLowerCase() === wanted;
  return [...results.filter(isExact), ...results.filter((r) => !isExact(r))];
}
