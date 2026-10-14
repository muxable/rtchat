// Channels whose login is exactly the query go first, so an exact kick match
// isn't buried under twitch's fuzzy results.
export function exactMatchesFirst<T extends { login: string }>(
  results: T[],
  query: string
) {
  const wanted = query.trim().toLowerCase();
  const isExact = (result: T) => result.login?.toLowerCase() === wanted;
  return [...results.filter(isExact), ...results.filter((r) => !isExact(r))];
}
