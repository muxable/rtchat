import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["test/**/*.test.ts"],
    env: {
      // functions.config() reads runtime config from this variable.
      CLOUD_RUNTIME_CONFIG: JSON.stringify({
        twitch: { id: "twitch-id", secret: "twitch-secret" },
        kick: { id: "kick-id", secret: "kick-secret" },
        streamlabs: { id: "sl-id", secret: "sl-secret" },
        streamelements: { id: "se-id", secret: "se-secret" },
      }),
    },
  },
});
